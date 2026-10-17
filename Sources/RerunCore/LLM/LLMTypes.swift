import Foundation

public enum LLMProviderID: String, Codable, CaseIterable, Hashable, Sendable {
    case anthropic, openai, gemini
    /// Apple's on-device model (macOS 26+ with Apple Intelligence). No key, no network.
    case onDevice

    /// Providers that need an API key.
    public static let cloud: [LLMProviderID] = [.anthropic, .openai, .gemini]

    public var displayName: String {
        switch self {
        case .anthropic: "Anthropic (Claude)"
        case .openai: "OpenAI"
        case .gemini: "Google Gemini"
        case .onDevice: "On this Mac"
        }
    }

    /// Model used when a route names this provider without a model.
    /// Editable in Settings; check each provider's docs for newer models.
    public var defaultModel: String {
        switch self {
        case .anthropic: "claude-opus-5-5"
        case .openai: "gpt-5"
        case .gemini: "gemini-2.5-pro"
        case .onDevice: "apple-on-device"
        }
    }

    public var isCloud: Bool { self != .onDevice }
}

/// Which provider and model handle a story turn.
public struct ModelRoute: Codable, Hashable, Sendable {
    public var provider: LLMProviderID
    public var model: String

    public init(provider: LLMProviderID, model: String? = nil) {
        self.provider = provider
        self.model = model ?? provider.defaultModel
    }
}

public struct LLMMessage: Codable, Hashable, Sendable {
    public enum Role: String, Codable, Sendable { case user, assistant }

    public var role: Role
    public var text: String

    public init(_ role: Role, _ text: String) {
        self.role = role
        self.text = text
    }
}

public struct LLMRequest: Sendable {
    public var model: String
    public var system: String
    public var messages: [LLMMessage]
    public var maxTokens: Int
    /// Ask the provider for a JSON object back (where it supports that).
    public var wantsJSON: Bool

    public init(model: String, system: String, messages: [LLMMessage], maxTokens: Int = 16_000, wantsJSON: Bool = true) {
        self.model = model
        self.system = system
        self.messages = messages
        self.maxTokens = maxTokens
        self.wantsJSON = wantsJSON
    }
}

public struct LLMResponse: Sendable {
    public var text: String
    /// The model that actually answered (can differ after a server-side fallback).
    public var model: String
}

public enum LLMError: Error, Equatable, CustomStringConvertible {
    case missingAPIKey(LLMProviderID)
    case noProviderConfigured
    case http(status: Int, body: String)
    case refused(category: String?)
    case emptyResponse
    case malformedResponse(String)
    case onDeviceUnavailable

    public var description: String {
        switch self {
        case .missingAPIKey(let provider): "No API key saved for \(provider.displayName)."
        case .noProviderConfigured: "Add an API key in Settings to generate stories."
        case .http(let status, let body): "The model provider returned HTTP \(status): \(body.prefix(300))"
        case .refused(let category): "The model declined this scene" + (category.map { " (\($0))" } ?? "") + "."
        case .emptyResponse: "The model returned an empty response."
        case .malformedResponse(let detail): "Couldn't read the model's response: \(detail)"
        case .onDeviceUnavailable: "The on-device model needs macOS 26 with Apple Intelligence turned on."
        }
    }
}

/// One provider's API.
public protocol LLMClient: Sendable {
    func complete(_ request: LLMRequest) async throws -> LLMResponse
}
