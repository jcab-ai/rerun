import Foundation

/// What kind of scene a moment is. Drives evidence styling and model routing.
public enum MomentTag: String, Codable, CaseIterable, Hashable, Sendable, CodingKeyRepresentable {
    case trip, romance, fight, celebration, food, family, chaos, milestone, everyday

    /// Handwritten label for filters and stickers.
    public var label: String {
        switch self {
        case .trip: "trips"
        case .romance: "romance"
        case .fight: "fights"
        case .celebration: "parties"
        case .food: "food"
        case .family: "family"
        case .chaos: "chaos"
        case .milestone: "milestones"
        case .everyday: "everyday"
        }
    }
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

/// Named details a prop can print. Anything missing is filled in from the moment.
public enum EvidenceField: String, Codable, Hashable, Sendable, CodingKeyRepresentable {
    // Boarding pass
    case carrier, from, to, flight, gate, boarding, seat, passenger
    // Receipt
    case merchant, total
    // Ticket stub
    case event, section, row
    // Any prop
    case date, stamp, caption, duration
}

/// One printed line on a receipt.
public struct EvidenceItem: Codable, Hashable, Sendable {
    public var label: String
    public var amount: String?

    public init(_ label: String, _ amount: String? = nil) {
        self.label = label
        self.amount = amount
    }
}

public struct Evidence: Codable, Hashable, Sendable {
    public var kind: EvidenceKind
    /// Overrides the kind's label, e.g. "tow receipt".
    public var label: String?
    public var details: [EvidenceField: String]
    public var items: [EvidenceItem]

    public init(_ kind: EvidenceKind, label: String? = nil, details: [EvidenceField: String] = [:], items: [EvidenceItem] = []) {
        self.kind = kind
        self.label = label
        self.details = details
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(EvidenceKind.self, forKey: .kind)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        details = try c.decode(.details, default: [:])
        items = try c.decode(.items, default: [])
    }

    public var displayLabel: String { label ?? kind.label }

    public subscript(_ field: EvidenceField) -> String? { details[field] }
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

public struct Moment: StoredRecord, Hashable, Sendable {
    public static let table = "moments"

    public var id: String
    public var title: String
    /// True until a model (or the user) has named it; detector titles are placeholders.
    public var titleIsProvisional: Bool
    /// A small-caps aside under the date ("the quiet month").
    public var tagline: String?
    /// A pencilled fact ("23 days, no texts").
    public var stat: String?
    public var date: Date
    public var endDate: Date?
    public var primaryPersonID: String
    public var personIDs: [String]
    public var tag: MomentTag
    public var evidence: Evidence?
    /// Where the evidence came from ("from Maya's photos & your Wallet").
    public var evidenceSource: String?
    /// Caption on the polaroid pinned next to the evidence ("gate 14, 6:58am").
    public var photoCaption: String?
    /// One real text from the moment, shown as a bubble.
    public var quote: String?
    public var location: String?
    public var summary: String
    public var messageCount: Int
    public var chapterCount: Int
    public var source: MomentSource?
    public var playCount: Int
    public var lastPlayedAt: Date?
    /// How the last playthrough ended ("you caught the 9:15").
    public var lastOutcome: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        titleIsProvisional: Bool = false,
        tagline: String? = nil,
        stat: String? = nil,
        date: Date,
        endDate: Date? = nil,
        primaryPersonID: String,
        personIDs: [String]? = nil,
        tag: MomentTag,
        evidence: Evidence? = nil,
        evidenceSource: String? = nil,
        photoCaption: String? = nil,
        quote: String? = nil,
        location: String? = nil,
        summary: String = "",
        messageCount: Int = 0,
        chapterCount: Int = 4,
        source: MomentSource? = nil,
        playCount: Int = 0,
        lastPlayedAt: Date? = nil,
        lastOutcome: String? = nil
    ) {
        self.id = id
        self.title = title
        self.titleIsProvisional = titleIsProvisional
        self.tagline = tagline
        self.stat = stat
        self.date = date
        self.endDate = endDate
        self.primaryPersonID = primaryPersonID
        self.personIDs = personIDs ?? [primaryPersonID]
        self.tag = tag
        self.evidence = evidence
        self.evidenceSource = evidenceSource
        self.photoCaption = photoCaption
        self.quote = quote
        self.location = location
        self.summary = summary
        self.messageCount = messageCount
        self.chapterCount = chapterCount
        self.source = source
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
        self.lastOutcome = lastOutcome
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        titleIsProvisional = try c.decode(.titleIsProvisional, default: false)
        tagline = try c.decodeIfPresent(String.self, forKey: .tagline)
        stat = try c.decodeIfPresent(String.self, forKey: .stat)
        date = try c.decode(Date.self, forKey: .date)
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate)
        primaryPersonID = try c.decode(String.self, forKey: .primaryPersonID)
        personIDs = try c.decode(.personIDs, default: [primaryPersonID])
        tag = try c.decode(.tag, default: .everyday)
        evidence = try c.decodeIfPresent(Evidence.self, forKey: .evidence)
        evidenceSource = try c.decodeIfPresent(String.self, forKey: .evidenceSource)
        photoCaption = try c.decodeIfPresent(String.self, forKey: .photoCaption)
        quote = try c.decodeIfPresent(String.self, forKey: .quote)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        summary = try c.decode(.summary, default: "")
        messageCount = try c.decode(.messageCount, default: 0)
        chapterCount = try c.decode(.chapterCount, default: 4)
        source = try c.decodeIfPresent(MomentSource.self, forKey: .source)
        playCount = try c.decode(.playCount, default: 0)
        lastPlayedAt = try c.decodeIfPresent(Date.self, forKey: .lastPlayedAt)
        lastOutcome = try c.decodeIfPresent(String.self, forKey: .lastOutcome)
    }

    public var hasBeenPlayed: Bool { playCount > 0 }

    /// How long the real conversation ran.
    public var duration: TimeInterval? {
        endDate.map { $0.timeIntervalSince(date) }
    }

    /// "2 hrs 11 min", "3 days", "40 min"
    public var durationLabel: String? {
        guard let duration, duration >= 60 else { return nil }
        let minutes = Int(duration / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        if hours < 48 { return minutes % 60 == 0 ? "\(hours) hrs" : "\(hours) hrs \(minutes % 60) min" }
        return "\(hours / 24) days"
    }

    /// "4 chapters · ~12 min"
    public var lengthLabel: String {
        "\(chapterCount) chapter\(chapterCount == 1 ? "" : "s") · ~\(chapterCount * 3) min"
    }

    /// Number of physical things on the evidence board.
    public var evidenceCount: Int {
        (evidence == nil ? 0 : 1) + (photoCaption == nil ? 0 : 1) + (quote == nil ? 0 : 1)
    }
}
