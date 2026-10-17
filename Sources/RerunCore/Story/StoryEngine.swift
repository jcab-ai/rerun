import Foundation

public enum StoryError: Error, Equatable {
    case turnDenied(reason: String, retryAt: Date?)
    case noStoryteller
}

/// Anything that can write the next beat of a moment.
public protocol StoryTeller: Sendable {
    func nextBeat(for run: StoryRun, context: StoryContext) async throws -> StoryBeat
}

/// Generates story turns with a language model: routes each turn by scene
/// tag (or to the on-device model), builds the prompt, parses the reply.
/// Never sends a real message.
public struct StoryEngine: StoryTeller {
    let secrets: SecretStore
    let gate: TurnGate
    let transport: HTTPTransport
    let onDevice: @Sendable () -> LLMClient?

    public init(
        secrets: SecretStore,
        gate: TurnGate = UnlimitedTurns(),
        transport: HTTPTransport = URLSessionTransport(),
        onDevice: @escaping @Sendable () -> LLMClient? = { OnDeviceModel.client() }
    ) {
        self.secrets = secrets
        self.gate = gate
        self.transport = transport
        self.onDevice = onDevice
    }

    /// Providers that can take a turn right now.
    public func configuredProviders() -> Set<LLMProviderID> {
        var configured = Set(LLMProviderID.cloud.filter(secrets.hasAPIKey))
        if onDevice() != nil { configured.insert(.onDevice) }
        return configured
    }

    public func router(for settings: AppSettings) -> ModelRouter {
        ModelRouter(table: settings.routing, configured: configuredProviders())
    }

    /// Whether a turn could be generated with the current settings and keys.
    public func canTell(with settings: AppSettings) -> Bool {
        switch settings.storyModel {
        case .onDevice: onDevice() != nil
        case .cloud: !configuredProviders().isEmpty
        }
    }

    public func nextBeat(for run: StoryRun, context: StoryContext) async throws -> StoryBeat {
        if case .denied(let reason, let retryAt) = gate.check(momentID: run.momentID) {
            throw StoryError.turnDenied(reason: reason, retryAt: retryAt)
        }

        let route: ModelRoute
        let client: LLMClient
        if context.settings.storyModel == .onDevice {
            guard let local = onDevice() else { throw LLMError.onDeviceUnavailable }
            route = ModelRoute(provider: .onDevice)
            client = local
        } else {
            let tag = run.sceneTag(default: context.moment.tag)
            guard let decision = router(for: context.settings).route(for: tag) else {
                throw LLMError.noProviderConfigured
            }
            route = decision.route
            if route.provider == .onDevice {
                guard let local = onDevice() else { throw LLMError.onDeviceUnavailable }
                client = local
            } else {
                guard let cloud = secrets.client(for: route.provider, transport: transport) else {
                    throw LLMError.missingAPIKey(route.provider)
                }
                client = cloud
            }
        }

        // The on-device model has a small context window: send the slim prompt.
        let compact = route.provider == .onDevice
        let response = try await client.complete(LLMRequest(
            model: route.model,
            system: PromptBuilder.system(for: context, run: run, compact: compact),
            messages: PromptBuilder.messages(for: run, context: context),
            maxTokens: compact ? 1_500 : 16_000
        ))
        var beat = try StoryBeatParser.parse(response.text, chapter: run.currentChapter, cast: context.cast)
        if run.currentChapter > run.chapterCount {
            // The last chapter's choice has been made: this is the ending.
            beat.chapter = run.chapterCount
            beat.endsStory = true
            beat.choices = []
        }
        beat.route = ModelRoute(provider: route.provider, model: response.model)
        gate.recordTurn(momentID: run.momentID, at: Date())
        return beat
    }
}

/// Tries each teller in order: scripted stories first, then the model.
public struct LayeredStoryTeller: StoryTeller {
    let scripted: ScriptedStoryTeller
    let engine: StoryEngine
    let settings: AppSettings

    public init(scripted: ScriptedStoryTeller, engine: StoryEngine, settings: AppSettings) {
        self.scripted = scripted
        self.engine = engine
        self.settings = settings
    }

    public func canTell(_ momentID: String) -> Bool {
        scripted.canTell(momentID) || engine.canTell(with: settings)
    }

    public func nextBeat(for run: StoryRun, context: StoryContext) async throws -> StoryBeat {
        if scripted.canTell(run.momentID) {
            return try await scripted.nextBeat(for: run, context: context)
        }
        guard engine.canTell(with: context.settings) else { throw StoryError.noStoryteller }
        return try await engine.nextBeat(for: run, context: context)
    }
}
