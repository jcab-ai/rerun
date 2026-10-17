import Foundation

/// A value persisted as one JSON row in its own table.
public protocol StoredRecord: Codable, Identifiable where ID == String {
    static var table: String { get }
}

/// Local persistence for the world: people, moments, notes, voice profiles,
/// stories and settings. Each record type is a table of `(id, payload JSON)`.
/// Nothing here ever leaves the Mac.
public final class RecordStore: @unchecked Sendable {
    private let db: SQLiteDatabase
    private let lock = NSLock()
    private var knownTables: Set<String> = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        db = try SQLiteDatabase(url: url)
        try db.execute("PRAGMA journal_mode = WAL")
    }

    /// The default location: ~/Library/Application Support/Rerun/rerun.sqlite
    public static func defaultURL() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return support.appendingPathComponent("Rerun", isDirectory: true).appendingPathComponent("rerun.sqlite")
    }

    public func save<T: StoredRecord>(_ record: T) throws {
        try save([record])
    }

    public func save<T: StoredRecord>(_ records: [T]) throws {
        try locked {
            try ensureTable(T.table)
            try db.transaction {
                for record in records {
                    let payload = try encoder.encode(record)
                    try db.run(
                        "INSERT OR REPLACE INTO \(T.table) (id, payload, updated_at) VALUES (?, ?, ?)",
                        [.text(record.id), .blob(payload), .double(Date().timeIntervalSince1970)]
                    )
                }
            }
        }
    }

    public func all<T: StoredRecord>(_ type: T.Type) throws -> [T] {
        try locked {
            try ensureTable(T.table)
            var results: [T] = []
            try db.query("SELECT payload FROM \(T.table) ORDER BY rowid") { row in
                if let data = row.blob(0) {
                    results.append(try decoder.decode(T.self, from: data))
                }
            }
            return results
        }
    }

    public func get<T: StoredRecord>(_ type: T.Type, id: String) throws -> T? {
        try locked {
            try ensureTable(T.table)
            var result: T?
            try db.query("SELECT payload FROM \(T.table) WHERE id = ?", [.text(id)]) { row in
                if let data = row.blob(0) {
                    result = try decoder.decode(T.self, from: data)
                }
            }
            return result
        }
    }

    public func delete<T: StoredRecord>(_ type: T.Type, id: String) throws {
        try locked {
            try ensureTable(T.table)
            try db.run("DELETE FROM \(T.table) WHERE id = ?", [.text(id)])
        }
    }

    public func deleteAll<T: StoredRecord>(_ type: T.Type) throws {
        try locked {
            try ensureTable(T.table)
            try db.run("DELETE FROM \(T.table)")
        }
    }

    private func ensureTable(_ table: String) throws {
        guard !knownTables.contains(table) else { return }
        try db.execute("CREATE TABLE IF NOT EXISTS \(table) (id TEXT PRIMARY KEY, payload BLOB NOT NULL, updated_at REAL NOT NULL)")
        knownTables.insert(table)
    }

    private func locked<R>(_ body: () throws -> R) throws -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
