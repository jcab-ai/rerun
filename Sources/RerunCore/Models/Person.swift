import Foundation

/// Sticker colors: the mockup's five, seven more so a big world doesn't repeat
/// itself, and five the sidebar's screens keep to themselves. Core stays
/// UI-agnostic, so this is a key; RerunUI maps it to the actual palette.
public enum PersonColor: String, Codable, CaseIterable, Hashable, Sendable {
    case coral, blue, leaf, grape, sun
    case berry, cocoa, slate, olive, lavender, forest, peach
    case tangerine, pink, teal, sky, lime

    /// The order people get colors in, most distinct first.
    public static let peopleOrder: [PersonColor] = [.coral, .blue, .leaf, .grape, .sun, .berry, .cocoa, .slate, .olive, .lavender, .forest, .peach]

    /// One per sidebar screen, so a screen never shares a color with a person.
    public static let screenOrder: [PersonColor] = [.tangerine, .pink, .teal, .sky, .lime]

    /// Assignment order for people ranked by message count. Only a world
    /// bigger than the whole palette borrows the screens' colors, then repeats.
    public static func forRank(_ rank: Int) -> PersonColor {
        let order = peopleOrder + screenOrder
        return order[((rank % order.count) + order.count) % order.count]
    }
}

extension Array where Element == Person {
    /// Gives everyone included a color no one else included has (left-out
    /// people come after, and only repeat once the palette runs out). Earlier
    /// people keep their color first; a clash moves the later person.
    public func withDistinctColors() -> [Person] {
        let palette = PersonColor.peopleOrder + PersonColor.screenOrder
        var result = self
        var taken: Set<PersonColor> = []
        for included in [true, false] {
            for index in result.indices where result[index].included == included {
                if taken.contains(result[index].color), let free = palette.first(where: { !taken.contains($0) }) {
                    result[index].color = free
                }
                taken.insert(result[index].color)
            }
        }
        return result
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

    /// The letter on their avatar; "#" for someone known only by a number.
    public var initial: String {
        guard let letter = displayName.first(where: \.isLetter) else { return "#" }
        return letter.uppercased()
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
