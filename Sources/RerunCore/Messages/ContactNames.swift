import Foundation
#if canImport(Contacts)
import Contacts
#endif

/// Turns chat.db handles (phone numbers, emails) into names. Optional: the
/// people in your world come from your conversations, and anyone Contacts
/// doesn't know is shown by their number.
public protocol ContactNameResolving {
    func name(forHandle handle: String) -> String?
    /// The same id for every handle of one contact, so someone's phone and
    /// email threads become one person.
    func contactID(forHandle handle: String) -> String?
}

extension ContactNameResolving {
    public func contactID(forHandle handle: String) -> String? { nil }
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

    /// How to name a one-on-one thread Contacts doesn't know: the number the
    /// way you'd recognize it ("(415) 555-0100"), or the name part of an email.
    public static func readableName(_ handle: String) -> String {
        if handle.contains("@") { return fallbackName(handle) }
        let digits = handle.filter(\.isNumber)
        // US/Canada numbers: ten digits, or eleven starting with the country code 1.
        let isNorthAmerican = (digits.count == 10 && !handle.hasPrefix("+")) || (digits.count == 11 && digits.hasPrefix("1"))
        guard isNorthAmerican else { return handle }
        let national = digits.suffix(10)
        return "(\(national.prefix(3))) \(national.dropFirst(3).prefix(3))-\(national.suffix(4))"
    }

    /// A short fallback (group chat members) when we have no contact name.
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
    private var idByPhone: [String: String] = [:]
    private var idByEmail: [String: String] = [:]

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
        var idByPhone: [String: String] = [:]
        var idByEmail: [String: String] = [:]
        try? store.enumerateContacts(with: request) { contact, _ in
            let name = contact.nickname.isEmpty
                ? [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                : contact.nickname
            for phone in contact.phoneNumbers {
                guard let key = HandleFormat.phoneKey(phone.value.stringValue) else { continue }
                idByPhone[key] = contact.identifier
                if !name.isEmpty { byPhone[key] = name }
            }
            for email in contact.emailAddresses {
                let key = (email.value as String).lowercased()
                idByEmail[key] = contact.identifier
                if !name.isEmpty { byEmail[key] = name }
            }
        }
        self.byPhone = byPhone
        self.byEmail = byEmail
        self.idByPhone = idByPhone
        self.idByEmail = idByEmail
    }

    public func name(forHandle handle: String) -> String? {
        if handle.contains("@") { return byEmail[handle.lowercased()] }
        return HandleFormat.phoneKey(handle).flatMap { byPhone[$0] }
    }

    public func contactID(forHandle handle: String) -> String? {
        if handle.contains("@") { return idByEmail[handle.lowercased()] }
        return HandleFormat.phoneKey(handle).flatMap { idByPhone[$0] }
    }
}
#endif
