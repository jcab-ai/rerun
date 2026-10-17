import Foundation
#if canImport(SQLite3)
import SQLite3
#else
import CSQLite
#endif

public struct SQLiteError: Error, CustomStringConvertible {
    public let code: Int32
    public let message: String

    public var description: String { "SQLite error \(code): \(message)" }
}

public enum SQLiteValue: Sendable {
    case null
    case int(Int64)
    case double(Double)
    case text(String)
    case blob(Data)
}

/// A row cursor valid only inside the `query` callback.
public struct SQLiteRow {
    fileprivate let statement: OpaquePointer

    public func isNull(_ column: Int32) -> Bool {
        sqlite3_column_type(statement, column) == SQLITE_NULL
    }

    public func int(_ column: Int32) -> Int64 {
        sqlite3_column_int64(statement, column)
    }

    public func double(_ column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }

    public func text(_ column: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: cString)
    }

    public func blob(_ column: Int32) -> Data? {
        guard let bytes = sqlite3_column_blob(statement, column) else { return nil }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, column)))
    }
}

/// Minimal wrapper over the SQLite C API. Not thread-safe; callers serialize.
public final class SQLiteDatabase {
    private var handle: OpaquePointer?
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// Opens `url`. With `readOnly`, the file is opened through a `mode=ro`
    /// URI so SQLite itself refuses any write.
    public init(url: URL, readOnly: Bool = false) throws {
        let flags = readOnly
            ? SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
            : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        let path = readOnly ? url.absoluteString + "?mode=ro" : url.path
        let status = sqlite3_open_v2(path, &handle, flags, nil)
        guard status == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unable to open"
            sqlite3_close(handle)
            handle = nil
            throw SQLiteError(code: status, message: message)
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    public func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        let status = sqlite3_exec(handle, sql, nil, nil, &error)
        if status != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(error)
            throw SQLiteError(code: status, message: message)
        }
    }

    public func run(_ sql: String, _ bindings: [SQLiteValue] = []) throws {
        try query(sql, bindings) { _ in }
    }

    public func query(_ sql: String, _ bindings: [SQLiteValue] = [], row: (SQLiteRow) throws -> Void) throws {
        var statement: OpaquePointer?
        try check(sqlite3_prepare_v2(handle, sql, -1, &statement, nil))
        defer { sqlite3_finalize(statement) }
        guard let statement else { return }

        for (offset, value) in bindings.enumerated() {
            let index = Int32(offset + 1)
            switch value {
            case .null:
                try check(sqlite3_bind_null(statement, index))
            case .int(let int):
                try check(sqlite3_bind_int64(statement, index, int))
            case .double(let double):
                try check(sqlite3_bind_double(statement, index, double))
            case .text(let text):
                try check(sqlite3_bind_text(statement, index, text, -1, Self.transient))
            case .blob(let data):
                try data.withUnsafeBytes { buffer in
                    try check(sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), Self.transient))
                }
            }
        }

        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_ROW {
                try row(SQLiteRow(statement: statement))
            } else if status == SQLITE_DONE {
                return
            } else {
                try check(status)
            }
        }
    }

    public func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try body()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    public func tableExists(_ name: String) throws -> Bool {
        var exists = false
        try query("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?", [.text(name)]) { _ in exists = true }
        return exists
    }

    private func check(_ status: Int32) throws {
        guard status == SQLITE_OK else {
            throw SQLiteError(code: status, message: String(cString: sqlite3_errmsg(handle)))
        }
    }
}
