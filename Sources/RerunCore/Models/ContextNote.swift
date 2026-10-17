import Foundation

/// Something the user knows that the texts don't say ("Maya hates being
/// called dramatic", "this was the week after her dad's surgery").
/// Notes are fed into story generation for the person or moment they're about.
public struct ContextNote: StoredRecord, Hashable, Sendable {
    public static let table = "context_notes"

    public enum Subject: Codable, Hashable, Sendable {
        case person(String)
        case moment(String)
    }

    public var id: String
    public var subject: Subject
    public var body: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: String = UUID().uuidString, subject: Subject, body: String, createdAt: Date = Date()) {
        self.id = id
        self.subject = subject
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}

extension Array where Element == ContextNote {
    /// Notes relevant to a moment: the moment's own plus those on anyone in it.
    public func relevant(to moment: Moment) -> [ContextNote] {
        filter { note in
            switch note.subject {
            case .moment(let id): id == moment.id
            case .person(let id): moment.personIDs.contains(id)
            }
        }
        .sorted { $0.createdAt < $1.createdAt }
    }
}
