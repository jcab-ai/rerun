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
    public var displayName: String
    /// Phone numbers / emails from chat.db's `handle` table.
    public var handles: [String]
    /// chat.db `chat.ROWID`s that belong to this person or group.
    public var chatIDs: [Int64]
    public var isGroup: Bool
    public var color: PersonColor
    public var messageCount: Int
    /// Excluded people are never read again and never sent to a model.
    public var included: Bool

    public init(
        id: String = UUID().uuidString,
        displayName: String,
        handles: [String] = [],
        chatIDs: [Int64] = [],
        isGroup: Bool = false,
        color: PersonColor,
        messageCount: Int = 0,
        included: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.handles = handles
        self.chatIDs = chatIDs
        self.isGroup = isGroup
        self.color = color
        self.messageCount = messageCount
        self.included = included
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
