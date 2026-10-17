import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device language model ("On this Mac" in Settings). Prompts never
/// leave the Mac. Needs macOS 26 with Apple Intelligence enabled.
public enum OnDeviceModel {
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// A short reason to show when it isn't available.
    public static var unavailableReason: String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return ""
            case .unavailable: return "turn on Apple Intelligence in System Settings"
            }
        }
        #endif
        return "needs macOS 26 with Apple Intelligence"
    }

    public static func client() -> LLMClient? {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *), isAvailable {
            return FoundationModelsClient()
        }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
struct FoundationModelsClient: LLMClient {
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        let session = LanguageModelSession(instructions: request.system)
        // The session is fresh each turn, so replay the conversation as one prompt.
        let prompt = request.messages.map { message in
            (message.role == .user ? "PLAYER: " : "STORY ENGINE (previous turn): ") + message.text
        }.joined(separator: "\n\n") + "\n\nReply with only the JSON object for the next turn."
        let response = try await session.respond(to: prompt)
        let text = response.content
        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return LLMResponse(text: text, model: LLMProviderID.onDevice.defaultModel)
    }
}
#endif
