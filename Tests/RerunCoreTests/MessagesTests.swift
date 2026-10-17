import XCTest
@testable import RerunCore

final class AttributedBodyDecoderTests: XCTestCase {
    static func blob(_ text: String, longLength: Bool = false) -> Data {
        var bytes = Array("\u{04}\u{0B}streamtyped\u{81}\u{E8}\u{03}\u{84}\u{01}@\u{84}\u{84}\u{84}\u{12}NSAttributedString\u{00}\u{84}\u{84}\u{08}NSObject\u{00}\u{85}\u{92}\u{84}\u{84}\u{84}\u{08}".utf8)
        bytes += Array("NSString".utf8) + [0x01, 0x94, 0x84, 0x01, 0x2B]
        let utf8 = Array(text.utf8)
        if longLength {
            bytes += [0x81, UInt8(utf8.count & 0xFF), UInt8(utf8.count >> 8)]
        } else {
            bytes.append(UInt8(utf8.count))
        }
        bytes += utf8 + [0x86, 0x84, 0x02, 0x69, 0x49]
        return Data(bytes)
    }

    func testShortBody() {
        XCTAssertEqual(AttributedBodyDecoder.text(from: Self.blob("we are NOT missing this flight")), "we are NOT missing this flight")
    }

    func testLongBodyWithEmoji() {
        let text = String(repeating: "you have my bag and not a time machine 🧳 ", count: 6)
        XCTAssertEqual(AttributedBodyDecoder.text(from: Self.blob(text, longLength: true)), text)
    }

    func testGarbage() {
        XCTAssertNil(AttributedBodyDecoder.text(from: Data([0x00, 0x01, 0x02])))
        XCTAssertNil(AttributedBodyDecoder.text(from: Data("NSString".utf8)))
    }
}

final class ChatDatabaseReaderTests: XCTestCase {
    var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A tiny database with the parts of chat.db's schema rerun reads.
    func makeChatDB() throws -> URL {
        let url = directory.appendingPathComponent("chat.db")
        let db = try SQLiteDatabase(url: url)
        try db.execute("""
            CREATE TABLE handle (ROWID INTEGER PRIMARY KEY, id TEXT);
            CREATE TABLE chat (ROWID INTEGER PRIMARY KEY, guid TEXT, chat_identifier TEXT, display_name TEXT, style INTEGER);
            CREATE TABLE chat_handle_join (chat_id INTEGER, handle_id INTEGER);
            CREATE TABLE chat_message_join (chat_id INTEGER, message_id INTEGER);
            CREATE TABLE message (ROWID INTEGER PRIMARY KEY, date INTEGER, text TEXT, attributedBody BLOB,
                is_from_me INTEGER, handle_id INTEGER, cache_has_attachments INTEGER,
                associated_message_type INTEGER, item_type INTEGER);
            INSERT INTO handle VALUES (1, '+14155550100');
            INSERT INTO chat VALUES (1, 'iMessage;-;+14155550100', '+14155550100', '', 45);
            INSERT INTO chat_handle_join VALUES (1, 1);
            """)
        let base: Int64 = 740_000_000 * 1_000_000_000
        let rows: [(Int64, String?, Data?, Int64, Int64)] = [
            (1, "the gate is CLOSED", nil, 0, 0),
            (2, nil, AttributedBodyDecoderTests.blob("where are you"), 0, 0),
            (3, "two min away", nil, 1, 0),
            (4, "Loved “two min away”", nil, 0, 2000), // tapback: skipped
        ]
        for (id, text, body, fromMe, associated) in rows {
            try db.run(
                "INSERT INTO message VALUES (?, ?, ?, ?, ?, ?, 0, ?, 0)",
                [.int(id), .int(base + id * 60_000_000_000), text.map(SQLiteValue.text) ?? .null,
                 body.map(SQLiteValue.blob) ?? .null, .int(fromMe), .int(fromMe == 1 ? 0 : 1), .int(associated)]
            )
            try db.run("INSERT INTO chat_message_join VALUES (1, ?)", [.int(id)])
        }
        return url
    }

    func testReadsChatsAndMessagesFromSnapshot() throws {
        let source = try makeChatDB()
        let before = try Data(contentsOf: source)

        let snapshot = try MessagesSnapshot(source: source)
        let reader = ChatDatabaseReader(snapshot: snapshot)

        let chats = try reader.chats()
        XCTAssertEqual(chats.count, 1)
        XCTAssertEqual(chats[0].participantHandles, ["+14155550100"])
        XCTAssertFalse(chats[0].isGroup)

        let messages = try reader.messages(inChat: 1)
        XCTAssertEqual(messages.map(\.text), ["the gate is CLOSED", "where are you", "two min away"])
        XCTAssertEqual(messages.map(\.isFromMe), [false, false, true])
        XCTAssertEqual(messages[0].senderHandle, "+14155550100")
        XCTAssertNil(messages[2].senderHandle)

        // The snapshot is opened read-only, and the source file is untouched.
        XCTAssertThrowsError(try snapshot.database.run("DELETE FROM message"))
        XCTAssertEqual(try Data(contentsOf: source), before)
    }

    func testAppleTime() {
        XCTAssertEqual(ChatDatabaseReader.date(fromAppleTime: 0), Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertEqual(ChatDatabaseReader.date(fromAppleTime: 600_000_000), Date(timeIntervalSinceReferenceDate: 600_000_000))
        XCTAssertEqual(ChatDatabaseReader.date(fromAppleTime: 600_000_000_000_000_000), Date(timeIntervalSinceReferenceDate: 600_000_000))
    }

    func testHandleFormat() {
        XCTAssertEqual(HandleFormat.phoneKey("+1 (415) 555-0100"), "4155550100")
        XCTAssertEqual(HandleFormat.phoneKey("4155550100"), "4155550100")
        XCTAssertNil(HandleFormat.phoneKey("maya@example.com"))
        XCTAssertEqual(HandleFormat.fallbackName("maya@example.com"), "maya")
        XCTAssertEqual(HandleFormat.fallbackName("+14155550100"), "…0100")
        XCTAssertEqual(HandleFormat.readableName("+14155550100"), "(415) 555-0100")
        XCTAssertEqual(HandleFormat.readableName("4155550100"), "(415) 555-0100")
        XCTAssertEqual(HandleFormat.readableName("+447700900123"), "+447700900123")
        XCTAssertEqual(HandleFormat.readableName("22395"), "22395")
        XCTAssertEqual(HandleFormat.readableName("maya@example.com"), "maya")
    }
}
