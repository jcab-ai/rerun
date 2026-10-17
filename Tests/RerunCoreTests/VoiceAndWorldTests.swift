import XCTest
@testable import RerunCore

func thread(_ lines: [(Bool, String)], start: Date = Date(timeIntervalSinceReferenceDate: 700_000_000), spacing: TimeInterval = 30) -> [ChatMessage] {
    lines.enumerated().map { index, line in
        ChatMessage(rowID: Int64(index + 1), date: start.addingTimeInterval(Double(index) * spacing), text: line.1, isFromMe: line.0)
    }
}

final class VoiceProfilerTests: XCTestCase {
    func testLowercaseBurstyTexter() {
        let messages = thread([
            (false, "the gate is CLOSED"), (false, "like closed closed"), (false, "lmaooo im on the floor"),
            (true, "two min away"),
            (false, "you have my bag"), (false, "and not a time machine"), (false, "WHY did we do one more song"),
            (true, "running"),
            (false, "ngl this is kind of funny"), (false, "lmaooo"),
        ])
        let profile = VoiceProfiler().profile(id: "maya", thread: messages) { !$0.isFromMe }

        XCTAssertEqual(profile.sampleCount, 8)
        XCTAssertGreaterThan(profile.lowercaseRate, 0.6)
        XCTAssertGreaterThan(profile.shoutRate, 0.2)
        XCTAssertEqual(profile.burstSize, 8.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(profile.laughs, ["lmaooo"])
        XCTAssertEqual(profile.medianReplySeconds, 30)
        XCTAssertTrue(profile.traits.contains("panics in bursts"))
    }

    func testSignOffAndPeriods() {
        let messages = thread([
            (false, "Ok. Call me when you land. - Dad"), (true, "will do"),
            (false, "Did you eat. - Dad"), (true, "yes"),
            (false, "Your mother says hi. - Dad"), (true, "hi mom"),
            (false, "Good."),
        ])
        let profile = VoiceProfiler().profile(id: "dad", thread: messages) { !$0.isFromMe }
        XCTAssertEqual(profile.signOff, "- Dad")
        XCTAssertEqual(profile.terminalPeriodRate, 1)
        XCTAssertEqual(profile.lowercaseRate, 0)
        XCTAssertTrue(profile.summary.contains("full stops always"))
        XCTAssertTrue(profile.promptDescription(name: "Dad", includeExamples: true).contains("signs off with \"- Dad\""))
    }

    func testEmojiAndExamplesSkipNumbers() {
        let messages = thread([
            (false, "omg yes 😂😂"), (false, "call me at 4155550100"), (false, "see you there ❤️"), (false, "check https://example.com"),
        ])
        let profile = VoiceProfiler().profile(id: "p", thread: messages) { !$0.isFromMe }
        XCTAssertEqual(profile.topEmoji.first, "😂")
        XCTAssertEqual(profile.emojiPerMessage, 0.75)
        XCTAssertEqual(profile.examples, ["omg yes 😂😂", "see you there ❤️"])
    }
}

final class MomentDetectorTests: XCTestCase {
    func testSplitsSessionsAndTagsTrips() {
        var lines: [(Bool, String)] = []
        for index in 0..<20 {
            lines.append((index % 2 == 0, index == 3 ? "the gate is closed at the airport" : "we missed the flight!! boarding was at 6"))
        }
        let trip = thread(lines)
        let later = thread([(false, "hey"), (true, "hi")], start: trip.last!.date.addingTimeInterval(86_400))
        var detector = MomentDetector()
        detector.minMessages = 10

        XCTAssertEqual(detector.sessions(in: trip + later).count, 2)
        let moments = detector.detect(in: trip + later)
        XCTAssertEqual(moments.count, 1)
        XCTAssertEqual(moments[0].tag, .trip)
        XCTAssertEqual(moments[0].messageCount, 20)
        XCTAssertEqual(EvidenceKind.forTag(moments[0].tag), .boardingPass)
    }

    func testEverydayWhenNothingStandsOut() {
        XCTAssertEqual(MomentDetector().classify(["hey", "what's up", "nm"]).0, .everyday)
    }
}

final class WorldLayoutTests: XCTestCase {
    func makeWorld() -> ([Person], [Moment]) {
        let people = (0..<6).map { Person(id: "p\($0)", displayName: "P\($0)", color: .forRank($0), messageCount: 1000 - $0 * 100) }
        var moments: [Moment] = []
        for person in people {
            for index in 0..<5 {
                moments.append(Moment(id: "\(person.id)-m\(index)", title: "M", date: Date(timeIntervalSinceReferenceDate: Double(index) * 1e6), primaryPersonID: person.id, tag: .everyday, messageCount: index * 10))
            }
        }
        moments[0].playCount = 1
        moments[0].lastPlayedAt = Date()
        return (people, moments)
    }

    func testLayoutIsDeterministicAndInBounds() {
        let (people, moments) = makeWorld()
        let first = WorldLayout().layout(people: people, moments: moments)
        let second = WorldLayout().layout(people: people.reversed(), moments: moments.reversed())
        XCTAssertEqual(first.nodes.map(\.momentID).sorted(), second.nodes.map(\.momentID).sorted())

        XCTAssertEqual(first.nodes.count, 15, "the sticker budget, spread over all 6 people")
        XCTAssertEqual(first.hubs.count, 6)
        XCTAssertEqual(first.hubs.compactMap(\.hiddenCount).sorted(), [2, 2, 2, 3, 3, 3], "the biggest threads get the spare stickers")
        XCTAssertEqual(first.links.count, 6)
        XCTAssertTrue(first.nodes.contains { $0.momentID.hasPrefix("p5") }, "everyone included gets a slice")

        for node in first.nodes {
            XCTAssertGreaterThanOrEqual(node.position.x - node.width / 2, 0)
            XCTAssertLessThanOrEqual(node.position.x + node.width / 2, WorldMap.canvasWidth)
            XCTAssertTrue((0...WorldMap.canvasHeight).contains(node.position.y))
            XCTAssertTrue((2...6).contains(abs(node.tilt)))
        }
        XCTAssertEqual(first.node(for: "p0-m0")?.width, 178, "the last played moment is featured")
    }

    func testBigWorldsStillShowEveryone() {
        let people = (0..<20).map { Person(id: "p\($0)", displayName: "P\($0)", color: .forRank($0), messageCount: 5000 - $0 * 100) }
        let moments = people.flatMap { person in
            (0..<4).map { Moment(id: "\(person.id)-m\($0)", title: "M", date: Date(timeIntervalSinceReferenceDate: Double($0) * 1e6), primaryPersonID: person.id, tag: .everyday) }
        }
        let map = WorldLayout().layout(people: people, moments: moments)
        XCTAssertEqual(map.nodes.count, 20, "one sticker each once the budget runs out")
        XCTAssertEqual(map.hubs.count, 20, "the rest wait behind a +N hub")
    }

    func testStickerQuotasFavorBiggestThreads() {
        XCTAssertEqual(WorldLayout().stickerQuotas(available: [5, 5, 5, 5, 5, 5]), [3, 3, 3, 2, 2, 2])
        XCTAssertEqual(WorldLayout().stickerQuotas(available: [1, 9]), [1, 3])
        XCTAssertEqual(WorldLayout().stickerQuotas(available: []), [])
    }

    func testIncludedPeopleNeverShareAColor() {
        var people = (0..<14).map { Person(id: "p\($0)", displayName: "P\($0)", color: PersonColor.peopleOrder[$0 % 5], included: $0 < 12) }
        people = people.withDistinctColors()
        let included = people.filter(\.included).map(\.color)
        XCTAssertEqual(Set(included).count, 12)
        XCTAssertTrue(included.allSatisfy { PersonColor.peopleOrder.contains($0) }, "screens' colors are only borrowed past 12")
        XCTAssertEqual(people[0].color, .coral, "the first person keeps theirs")
        XCTAssertEqual(Set(people.map(\.color)).count, 14)
        XCTAssertTrue(Set(PersonColor.peopleOrder).isDisjoint(with: PersonColor.screenOrder))
        XCTAssertEqual(Set(PersonColor.peopleOrder + PersonColor.screenOrder), Set(PersonColor.allCases))
    }

    func testDemoWorldIsConsistent() {
        let momentIDs = Set(DemoWorld.moments.map(\.id))
        let personIDs = Set(DemoWorld.people.map(\.id))
        XCTAssertTrue(Set(DemoWorld.map.nodes.map(\.momentID)).isSubset(of: momentIDs))
        XCTAssertEqual(DemoWorld.map.nodes.count, 11, "the mockup's eleven stickers")
        XCTAssertTrue(DemoWorld.moments.allSatisfy { $0.personIDs.allSatisfy(personIDs.contains) })
        XCTAssertTrue(DemoWorld.map.links.allSatisfy { momentIDs.contains($0.fromMomentID) && momentIDs.contains($0.toMomentID) })
        XCTAssertEqual(DemoWorld.map.momentCount, 412)
    }
}

final class RecordStoreTests: XCTestCase {
    func testRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/rerun.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = try RecordStore(url: url)

        try store.save(DemoWorld.moments)
        try store.save(DemoWorld.map)
        let note = ContextNote(subject: .person("maya"), body: "Maya hates being called dramatic.")
        try store.save(note)

        XCTAssertEqual(try store.all(Moment.self), DemoWorld.moments)
        XCTAssertEqual(try store.get(WorldMap.self, id: WorldMap.singletonID), DemoWorld.map)
        XCTAssertEqual(try store.all(ContextNote.self).relevant(to: DemoWorld.moments[0]), [note])

        try store.delete(Moment.self, id: "lisbon")
        XCTAssertNil(try store.get(Moment.self, id: "lisbon"))
        XCTAssertEqual(try store.all(Moment.self).count, DemoWorld.moments.count - 1)
    }
}
