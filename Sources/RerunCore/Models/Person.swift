import Foundation

/// The five sticker colors from the mockup. Core stays UI-agnostic, so this is
/// a key; RerunUI maps it to the actual palette.
public enum PersonColor: String, Codable, CaseIterable, Hashable, Sendable {
    case coral, blue, leaf, grape, sun

    /// Assignment order for people ranked by message count.
    public static func forRank(_ rank: Int) -> PersonColor {
        let order: [PersonColor] = [.coral, .blue, .leaf, .grape, .sun]
        return order[((rank % order.count) + order.count) % order.count]
    }
}

/// A contact or group chat that appears in the world.
public struct Person: StoredRecord, Hashable, Sendable {
    public static let table = "people"

    public var id: String
    /// What you call them ("Dad", "the ducks").
    public var displayName: String
    /// Their name as Contacts has it ("Michael Rowe"), when it's different.
    public var fullName: String?
    /// "best friend · since sophomore year". Editable; scans leave it alone.
    public var relationship: String?
    /// Phone numbers / emails from chat.db's `handle` table.
    public var handles: [String]
    /// chat.db `chat.ROWID`s that belong to this person or group.
    public var chatIDs: [Int64]
    public var isGroup: Bool
    /// First names of a group's members, for the group's polaroid.
    public var members: [String]
    public var color: PersonColor
    public var messageCount: Int
    /// Every moment found with them, including ones not shown on the map.
    public var momentCount: Int
    /// When your texting history with them starts.
    public var since: Date?
    /// Excluded people are never read again and never sent to a model.
    public var included: Bool

    public init(
        id: String = UUID().uuidString,
        displayName: String,
        fullName: String? = nil,
        relationship: String? = nil,
        handles: [String] = [],
        chatIDs: [Int64] = [],
        isGroup: Bool = false,
        members: [String] = [],
        color: PersonColor,
        messageCount: Int = 0,
        momentCount: Int = 0,
        since: Date? = nil,
        included: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.fullName = fullName
        self.relationship = relationship
        self.handles = handles
        self.chatIDs = chatIDs
        self.isGroup = isGroup
        self.members = members
        self.color = color
        self.messageCount = messageCount
        self.momentCount = momentCount
        self.since = since
        self.included = included
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName)
        relationship = try c.decodeIfPresent(String.self, forKey: .relationship)
        handles = try c.decode(.handles, default: [])
        chatIDs = try c.decode(.chatIDs, default: [])
        isGroup = try c.decode(.isGroup, default: false)
        members = try c.decode(.members, default: [])
        color = try c.decode(.color, default: .coral)
        messageCount = try c.decode(.messageCount, default: 0)
        momentCount = try c.decode(.momentCount, default: 0)
        since = try c.decodeIfPresent(Date.self, forKey: .since)
        included = try c.decode(.included, default: true)
    }

    /// "the ducks" → "ducks" for tight spots like filter chips.
    public var shortName: String {
        displayName.lowercased().hasPrefix("the ")
            ? String(displayName.dropFirst(4))
            : displayName
    }

    public var initial: String {
        String(displayName.first.map { Character($0.uppercased()) } ?? "?")
    }

    /// "Maya Okafor", or the display name when Contacts didn't give us more.
    public var nameForTitles: String { fullName ?? displayName }

    /// "Dad (Michael Rowe)" for nicknames, otherwise just the name.
    public var captionName: String {
        guard let fullName, fullName != displayName, !fullName.hasPrefix(displayName) else { return fullName ?? displayName }
        return "\(displayName) (\(fullName))"
    }
}

/// The player — the "you" node at the center of the world.
public struct PlayerProfile: Codable, Hashable, Sendable {
    public var name: String
    public var age: Int?

    public init(name: String, age: Int? = nil) {
        self.name = name
        self.age = age
    }
}
