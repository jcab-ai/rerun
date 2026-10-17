import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Claude via the Messages API (raw HTTP; there is no official Swift SDK).
public struct AnthropicClient: LLMClient {
    let apiKey: String
    let transport: HTTPTransport
    var endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    public init(apiKey: String, transport: HTTPTransport = URLSessionTransport()) {
        self.apiKey = apiKey
        self.transport = transport
    }

    /// Models that accept `fallbacks: "default"`, which re-runs a request on
    /// another model server-side if a safety classifier declines it.
    static let serverFallbackModels: Set<String> = ["claude-opus-5-5", "claude-opus-5", "claude-fable-5-1", "claude-sonnet-5-5"]

    public func complete(_ request: LLMRequest) async throws -> LLMResponse {
        var headers = ["x-api-key": apiKey, "anthropic-version": "2023-06-01"]
        var body: [String: Any] = [
            "model": request.model,
            "max_tokens": request.maxTokens,
            "system": request.system,
            "messages": request.messages.map { ["role": $0.role.rawValue, "content": $0.text] },
            // Story turns are short creative writing; medium effort is plenty.
            "output_config": ["effort": "medium"],
        ]
        if Self.serverFallbackModels.contains(request.model) {
            headers["anthropic-beta"] = "server-side-fallback-2026-07-01"
            body["fallbacks"] = "default"
        }

        let json = try await JSONRequest.send(
            try JSONRequest.make(url: endpoint, headers: headers, body: body),
            via: transport
        )
        // A decline is HTTP 200 with stop_reason "refusal"; check before reading content.
        if json["stop_reason"] as? String == "refusal" {
            let details = json["stop_details"] as? [String: Any]
            throw LLMError.refused(category: details?["category"] as? String)
        }
        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks
            .filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return LLMResponse(text: text, model: json["model"] as? String ?? request.model)
    }
}

/// OpenAI Chat Completions.
public struct OpenAIClient: LLMClient {
    let apiKey: String
    let transport: HTTPTransport
    var endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    public init(apiKey: String, transport: HTTPTransport = URLSessionTransport()) {
        self.apiKey = apiKey
        self.transport = transport
    }

    public func complete(_ request: LLMRequest) async throws -> LLMResponse {
        var messages: [[String: Any]] = [["role": "system", "content": request.system]]
        messages += request.messages.map { ["role": $0.role.rawValue, "content": $0.text] }
        var body: [String: Any] = [
            "model": request.model,
            "messages": messages,
            "max_completion_tokens": request.maxTokens,
        ]
        if request.wantsJSON {
            body["response_format"] = ["type": "json_object"]
        }

        let json = try await JSONRequest.send(
            try JSONRequest.make(url: endpoint, headers: ["authorization": "Bearer \(apiKey)"], body: body),
            via: transport
        )
        let choice = (json["choices"] as? [[String: Any]])?.first
        let message = choice?["message"] as? [String: Any]
        if let refusal = message?["refusal"] as? String, !refusal.isEmpty {
            throw LLMError.refused(category: nil)
        }
        guard let text = message?["content"] as? String, !text.isEmpty else { throw LLMError.emptyResponse }
        return LLMResponse(text: text, model: json["model"] as? String ?? request.model)
    }
}

/// Google Gemini `generateContent`.
public struct GeminiClient: LLMClient {
    let apiKey: String
    let transport: HTTPTransport
    var baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!

    public init(apiKey: String, transport: HTTPTransport = URLSessionTransport()) {
        self.apiKey = apiKey
        self.transport = transport
    }

    public func complete(_ request: LLMRequest) async throws -> LLMResponse {
        var generationConfig: [String: Any] = ["maxOutputTokens": request.maxTokens]
        if request.wantsJSON {
            generationConfig["responseMimeType"] = "application/json"
        }
        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": request.system]]],
            "contents": request.messages.map {
                ["role": $0.role == .user ? "user" : "model", "parts": [["text": $0.text]]]
            },
            "generationConfig": generationConfig,
        ]
        let url = baseURL.appendingPathComponent("\(request.model):generateContent")

        let json = try await JSONRequest.send(
            try JSONRequest.make(url: url, headers: ["x-goog-api-key": apiKey], body: body),
            via: transport
        )
        if let feedback = json["promptFeedback"] as? [String: Any], let reason = feedback["blockReason"] as? String {
            throw LLMError.refused(category: reason)
        }
        let candidate = (json["candidates"] as? [[String: Any]])?.first
        if candidate?["finishReason"] as? String == "SAFETY" {
            throw LLMError.refused(category: "safety")
        }
        let parts = (candidate?["content"] as? [String: Any])?["parts"] as? [[String: Any]] ?? []
        let text = parts.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return LLMResponse(text: text, model: json["modelVersion"] as? String ?? request.model)
    }
}
