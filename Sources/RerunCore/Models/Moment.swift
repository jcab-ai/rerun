import Foundation

/// What kind of scene a moment is. Drives evidence styling and model routing.
public enum MomentTag: String, Codable, CaseIterable, Hashable, Sendable, CodingKeyRepresentable {
    case trip, romance, fight, celebration, food, family, chaos, milestone, everyday
}

/// The physical prop shown on the moment detail screen.
public enum EvidenceKind: String, Codable, CaseIterable, Hashable, Sendable {
    case boardingPass, receipt, ticketStub, polaroid, voiceMemo

    public var label: String {
        switch self {
        case .boardingPass: "boarding pass"
        case .receipt: "receipt"
        case .ticketStub: "ticket stub"
        case .polaroid: "polaroid"
        case .voiceMemo: "voice memo"
        }
    }

    /// Default prop style per moment type.
    public static func forTag(_ tag: MomentTag) -> EvidenceKind? {
        switch tag {
        case .trip: .boardingPass
        case .food: .receipt
        case .celebration: .ticketStub
        case .romance: .polaroid
        case .family: .voiceMemo
        case .fight, .chaos, .milestone, .everyday: nil
        }
    }
}

/// Where in chat.db a moment came from, so stories can re-read the real texts.
public struct MomentSource: Codable, Hashable, Sendable {
    public var chatID: Int64
    public var firstMessageRowID: Int64
    public var lastMessageRowID: Int64

    public init(chatID: Int64, firstMessageRowID: Int64, lastMessageRowID: Int64) {
        self.chatID = chatID
        self.firstMessageRowID = firstMessageRowID
        self.lastMessageRowID = lastMessageRowID
    }
}

public struct Evidence: Codable, Hashable, Sendable {
    public var kind: EvidenceKind
    /// Overrides the kind's label, e.g. "tow receipt".
    public var label: String?

    public init(_ kind: EvidenceKind, label: String? = nil) {
        self.kind = kind
        self.label = label
    }

    public var displayLabel: String { label ?? kind.label }
}

public struct Moment: StoredRecord, Hashable, Sendable {
    public static let table = "moments"

    public var id: String
    public var title: String
    /// True until a model (or the user) has named it; detector titles are placeholders.
    public var titleIsProvisional: Bool
    public var date: Date
    public var endDate: Date?
    public var primaryPersonID: String
    public var personIDs: [String]
    public var tag: MomentTag
    public var evidence: Evidence?
    public var location: String?
    public var summary: String
    public var messageCount: Int
    public var source: MomentSource?
    public var playCount: Int
    public var lastPlayedAt: Date?

    public init(
        id: String = UUID().uuidString,
        title: String,
        titleIsProvisional: Bool = false,
        date: Date,
        endDate: Date? = nil,
        primaryPersonID: String,
        personIDs: [String]? = nil,
        tag: MomentTag,
        evidence: Evidence? = nil,
        location: String? = nil,
        summary: String = "",
        messageCount: Int = 0,
        source: MomentSource? = nil,
        playCount: Int = 0,
        lastPlayedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.titleIsProvisional = titleIsProvisional
        self.date = date
        self.endDate = endDate
        self.primaryPersonID = primaryPersonID
        self.personIDs = personIDs ?? [primaryPersonID]
        self.tag = tag
        self.evidence = evidence
        self.location = location
        self.summary = summary
        self.messageCount = messageCount
        self.source = source
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
    }

    public var hasBeenPlayed: Bool { playCount > 0 }
}
