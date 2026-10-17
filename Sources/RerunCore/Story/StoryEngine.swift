import Foundation

public enum StoryError: Error, Equatable {
    case turnDenied(reason: String, retryAt: Date?)
}

/// Generates story turns: routes each turn to a model by scene tag, builds
/// the prompt, and parses the reply. Never sends a real message.
public struct StoryEngine: Sendable {
    let secrets: SecretStore
    let gate: TurnGate
    let transport: HTTPTransport

    public init(secrets: SecretStore, gate: TurnGate = UnlimitedTurns(), transport: HTTPTransport = URLSessionTransport()) {
        self.secrets = secrets
        self.gate = gate
        self.transport = transport
    }

    public func router(for settings: AppSettings) -> ModelRouter {
        ModelRouter(table: settings.routing, configured: Set(LLMProviderID.allCases.filter(secrets.hasAPIKey)))
    }

    public func nextBeat(for run: StoryRun, context: StoryContext) async throws -> StoryBeat {
        if case .denied(let reason, let retryAt) = gate.check(momentID: run.momentID) {
            throw StoryError.turnDenied(reason: reason, retryAt: retryAt)
        }
        let tag = run.sceneTag(default: context.moment.tag)
        guard let decision = router(for: context.settings).route(for: tag) else {
            throw LLMError.noProviderConfigured
        }
        guard let client = secrets.client(for: decision.route.provider, transport: transport) else {
            throw LLMError.missingAPIKey(decision.route.provider)
        }

        let response = try await client.complete(LLMRequest(
            model: decision.route.model,
            system: PromptBuilder.system(for: context),
            messages: PromptBuilder.messages(for: run, context: context)
        ))
        var beat = try StoryBeatParser.parse(response.text, chapter: run.currentChapter, cast: context.cast)
        beat.route = ModelRoute(provider: decision.route.provider, model: response.model)
        gate.recordTurn(momentID: run.momentID, at: Date())
        return beat
    }
}
