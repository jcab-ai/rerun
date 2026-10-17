import Foundation
#if canImport(Security)
import Security
#endif

/// Where API keys live. On macOS that's the login Keychain.
public protocol SecretStore: AnyObject, Sendable {
    func apiKey(for provider: LLMProviderID) -> String?
    func setAPIKey(_ key: String?, for provider: LLMProviderID) throws
}

extension SecretStore {
    public func hasAPIKey(for provider: LLMProviderID) -> Bool {
        !(apiKey(for: provider) ?? "").isEmpty
    }

    /// A client for `provider`, or nil when no key is saved.
    public func client(for provider: LLMProviderID, transport: HTTPTransport = URLSessionTransport()) -> LLMClient? {
        guard let key = apiKey(for: provider), !key.isEmpty else { return nil }
        switch provider {
        case .anthropic: return AnthropicClient(apiKey: key, transport: transport)
        case .openai: return OpenAIClient(apiKey: key, transport: transport)
        case .gemini: return GeminiClient(apiKey: key, transport: transport)
        }
    }
}

/// For tests and previews.
public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private var keys: [LLMProviderID: String]
    private let lock = NSLock()

    public init(_ keys: [LLMProviderID: String] = [:]) {
        self.keys = keys
    }

    public func apiKey(for provider: LLMProviderID) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return keys[provider]
    }

    public func setAPIKey(_ key: String?, for provider: LLMProviderID) throws {
        lock.lock()
        defer { lock.unlock() }
        keys[provider] = key
    }
}

#if canImport(Security)
public struct KeychainError: Error, CustomStringConvertible {
    public let status: OSStatus
    public var description: String { "Keychain error \(status)" }
}

/// API keys as generic passwords in the login Keychain, one per provider.
public final class KeychainSecretStore: SecretStore, @unchecked Sendable {
    private let service: String

    public init(service: String = "com.rerun.app.api-keys") {
        self.service = service
    }

    public func apiKey(for provider: LLMProviderID) -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func setAPIKey(_ key: String?, for provider: LLMProviderID) throws {
        let query = baseQuery(provider)
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
            return
        }
        let data = Data(trimmed.utf8)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            status = SecItemAdd(insert as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    private func baseQuery(_ provider: LLMProviderID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
        ]
    }
}
#endif
