import Foundation
#if canImport(Contacts)
import Contacts
#endif

/// Turns chat.db handles (phone numbers, emails) into names.
public protocol ContactNameResolving {
    func name(forHandle handle: String) -> String?
}

public struct NoContactNames: ContactNameResolving {
    public init() {}
    public func name(forHandle handle: String) -> String? { nil }
}

public enum HandleFormat {
    /// Last ten digits, so "+1 (415) 555-0100" and "4155550100" match.
    public static func phoneKey(_ handle: String) -> String? {
        let digits = handle.filter(\.isNumber)
        guard digits.count >= 7 else { return nil }
        return String(digits.suffix(10))
    }

    /// A readable fallback when we have no contact name.
    public static func fallbackName(_ handle: String) -> String {
        if handle.contains("@") {
            return String(handle.split(separator: "@").first ?? Substring(handle))
        }
        let digits = handle.filter(\.isNumber)
        return digits.count >= 4 ? "…" + digits.suffix(4) : handle
    }
}

#if canImport(Contacts)
/// Reads names from the user's Contacts (asks for Contacts permission once).
public final class SystemContactNames: ContactNameResolving {
    private var byPhone: [String: String] = [:]
    private var byEmail: [String: String] = [:]

    public init() {}

    public func load() async {
        let store = CNContactStore()
        guard (try? await store.requestAccess(for: .contacts)) == true else { return }
        let keys = [
            CNContactGivenNameKey, CNContactFamilyNameKey, CNContactNicknameKey,
            CNContactPhoneNumbersKey, CNContactEmailAddressesKey,
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var byPhone: [String: String] = [:]
        var byEmail: [String: String] = [:]
        try? store.enumerateContacts(with: request) { contact, _ in
            let name = contact.nickname.isEmpty
                ? [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                : contact.nickname
            guard !name.isEmpty else { return }
            for phone in contact.phoneNumbers {
                if let key = HandleFormat.phoneKey(phone.value.stringValue) { byPhone[key] = name }
            }
            for email in contact.emailAddresses {
                byEmail[(email.value as String).lowercased()] = name
            }
        }
        self.byPhone = byPhone
        self.byEmail = byEmail
    }

    public func name(forHandle handle: String) -> String? {
        if handle.contains("@") { return byEmail[handle.lowercased()] }
        return HandleFormat.phoneKey(handle).flatMap { byPhone[$0] }
    }
}
#endif
