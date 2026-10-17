import Foundation

/// Where Messages keeps its history, and whether we're allowed to read it.
public enum MessagesLibrary {
    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/chat.db")
    }

    public enum Access: Equatable, Sendable {
        case readable
        /// The file exists but macOS blocked us: Full Disk Access is off.
        case needsFullDiskAccess
        case missing
    }

    public static func access(at url: URL = defaultURL) -> Access {
        // Without Full Disk Access, TCC hides the file's contents even though
        // `fileExists` can still be true, so actually try to open it.
        if let handle = try? FileHandle(forReadingFrom: url) {
            try? handle.close()
            return .readable
        }
        let parent = url.deletingLastPathComponent().path
        if FileManager.default.fileExists(atPath: url.path) || FileManager.default.fileExists(atPath: parent) {
            return .needsFullDiskAccess
        }
        return .missing
    }
}

/// A private, read-only copy of chat.db.
///
/// rerun never opens the live Messages database. It copies `chat.db` (plus its
/// `-wal`/`-shm` sidecars, so recent messages are included) into a temporary
/// folder and opens *that* with SQLite's read-only mode. Nothing rerun does can
/// write to, lock, or send through Messages.
public final class MessagesSnapshot {
    public let database: SQLiteDatabase
    private let directory: URL

    public init(source: URL = MessagesLibrary.defaultURL) throws {
        let fileManager = FileManager.default
        directory = fileManager.temporaryDirectory.appendingPathComponent("rerun-snapshot-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let copy = directory.appendingPathComponent("chat.db")
        do {
            try fileManager.copyItem(at: source, to: copy)
            for suffix in ["-wal", "-shm"] {
                let sidecar = URL(fileURLWithPath: source.path + suffix)
                if fileManager.fileExists(atPath: sidecar.path) {
                    try fileManager.copyItem(at: sidecar, to: URL(fileURLWithPath: copy.path + suffix))
                }
            }
            database = try SQLiteDatabase(url: copy, readOnly: true)
        } catch {
            try? fileManager.removeItem(at: directory)
            throw error
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }
}

public struct ChatSummary: Hashable, Sendable {
    public var id: Int64
    public var guid: String
    public var identifier: String
    public var displayName: String?
    public var isGroup: Bool
    public var participantHandles: [String]
    public var messageCount: Int
    public var lastMessageAt: Date?
}

public struct ChatMessage: Hashable, Sendable {
    public var rowID: Int64
    public var date: Date
    public var text: String
    public var isFromMe: Bool
    /// The sender's phone/email, nil for your own messages.
    public var senderHandle: String?
    public var hasAttachments: Bool

    public init(rowID: Int64, date: Date, text: String, isFromMe: Bool, senderHandle: String? = nil, hasAttachments: Bool = false) {
        self.rowID = rowID
        self.date = date
        self.text = text
        self.isFromMe = isFromMe
        self.senderHandle = senderHandle
        self.hasAttachments = hasAttachments
    }
}

/// Read-only queries against a `MessagesSnapshot`.
public struct ChatDatabaseReader {
    private let db: SQLiteDatabase

    public init(snapshot: MessagesSnapshot) {
        db = snapshot.database
    }

    /// For tests: read any database laid out like chat.db.
    public init(database: SQLiteDatabase) {
        db = database
    }

    /// chat.db stores dates as time since 2001-01-01, in seconds on old macOS
    /// and nanoseconds since High Sierra.
    public static func date(fromAppleTime value: Int64) -> Date {
        let seconds = value > 1_000_000_000_000 ? Double(value) / 1_000_000_000 : Double(value)
        return Date(timeIntervalSinceReferenceDate: seconds)
    }

    public func chats() throws -> [ChatSummary] {
        var participants: [Int64: [String]] = [:]
        try db.query("""
            SELECT chj.chat_id, h.id FROM chat_handle_join chj
            JOIN handle h ON h.ROWID = chj.handle_id
            """) { row in
            if let handle = row.text(1) {
                participants[row.int(0), default: []].append(handle)
            }
        }

        var chats: [ChatSummary] = []
        try db.query("""
            SELECT c.ROWID, c.guid, c.chat_identifier, c.display_name, c.style,
                   COUNT(m.ROWID), MAX(m.date)
            FROM chat c
            LEFT JOIN chat_message_join cmj ON cmj.chat_id = c.ROWID
            LEFT JOIN message m ON m.ROWID = cmj.message_id
            GROUP BY c.ROWID
            """) { row in
            let id = row.int(0)
            let handles = participants[id] ?? []
            let name = row.text(3).flatMap { $0.isEmpty ? nil : $0 }
            chats.append(ChatSummary(
                id: id,
                guid: row.text(1) ?? "",
                identifier: row.text(2) ?? "",
                displayName: name,
                // style 43 is a group thread, 45 a one-to-one thread.
                isGroup: row.int(4) == 43 || handles.count > 1,
                participantHandles: handles,
                messageCount: Int(row.int(5)),
                lastMessageAt: row.isNull(6) ? nil : Self.date(fromAppleTime: row.int(6))
            ))
        }
        return chats
    }

    /// Text messages in a chat, oldest first. Tapbacks, edits-as-rows and
    /// system items (renames, member changes) are skipped.
    public func messages(inChat chatID: Int64) throws -> [ChatMessage] {
        var messages: [ChatMessage] = []
        try db.query("""
            SELECT m.ROWID, m.date, m.text, m.attributedBody, m.is_from_me, h.id, m.cache_has_attachments
            FROM chat_message_join cmj
            JOIN message m ON m.ROWID = cmj.message_id
            LEFT JOIN handle h ON h.ROWID = m.handle_id
            WHERE cmj.chat_id = ?
              AND COALESCE(m.associated_message_type, 0) = 0
              AND COALESCE(m.item_type, 0) = 0
            ORDER BY m.date
            """, [.int(chatID)]) { row in
            let text = row.text(2) ?? row.blob(3).flatMap(AttributedBodyDecoder.text(from:))
            // U+FFFC is the attachment placeholder character.
            guard let text = text?.replacingOccurrences(of: "\u{FFFC}", with: "").trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }
            let isFromMe = row.int(4) == 1
            messages.append(ChatMessage(
                rowID: row.int(0),
                date: Self.date(fromAppleTime: row.int(1)),
                text: text,
                isFromMe: isFromMe,
                senderHandle: isFromMe ? nil : row.text(5),
                hasAttachments: row.int(6) != 0
            ))
        }
        return messages
    }
}
