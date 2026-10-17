import XCTest
@testable import RerunCore

final class ScriptedStoryTests: XCTestCase {
    func context(_ momentID: String) -> StoryContext {
        let moment = DemoWorld.moments.first { $0.id == momentID }!
        let cast = moment.personIDs.compactMap { id in DemoWorld.people.first { $0.id == id } }.map { person in
            CastMember(person: person, voice: DemoWorld.voices.first { $0.id == person.id })
        }
        return StoryContext(moment: moment, cast: cast, notes: [], settings: DemoWorld.settings())
    }

    func testEveryDemoStoryMatchesItsMoment() {
        let teller = ScriptedStoryTeller(stories: DemoStories.all, typingDelay: .zero)
        for moment in DemoWorld.moments {
            XCTAssertTrue(teller.canTell(moment.id), "\(moment.id) has no script")
            XCTAssertEqual(teller.chapterCount(for: moment.id), moment.chapterCount, moment.id)
        }
        for story in DemoStories.all {
            XCTAssertTrue(story.chapters.allSatisfy { $0.choices.count == 3 }, "\(story.momentID): every chapter offers three choices")
            XCTAssertTrue(story.chapters.last!.choices.allSatisfy { $0.outcome != nil }, "\(story.momentID): every ending has an outcome")
        }
    }

    func testLisbonPlaysToTheEnd() async throws {
        let teller = ScriptedStoryTeller(stories: DemoStories.all, typingDelay: .zero)
        let context = context("lisbon")
        var run = StoryRun(momentID: "lisbon", chapterCount: 4)

        for chapter in 1...4 {
            var beat = try await teller.nextBeat(for: run, context: context)
            XCTAssertEqual(beat.chapter, chapter)
            XCTAssertEqual(beat.choices.count, 3)
            XCTAssertFalse(beat.endsStory)
            if chapter > 1 { XCTAssertFalse(beat.reactions.isEmpty, "chapter \(chapter) reacts to the last pick") }
            beat.pickedChoice = 0
            run.beats.append(beat)
        }
        XCTAssertEqual(run.beats[1].chapterTitle, "gate 14")
        XCTAssertEqual(run.beats[1].messages.first?.text, "jules")

        let ending = try await teller.nextBeat(for: run, context: context)
        XCTAssertTrue(ending.endsStory)
        XCTAssertTrue(ending.choices.isEmpty)
        XCTAssertEqual(ending.outcome, "you caught the 9:15")
        run.beats.append(ending)
        XCTAssertTrue(run.isFinished)
        XCTAssertEqual(run.outcome, "you caught the 9:15")
        XCTAssertTrue(run.transcript.contains { $0.isFromPlayer && $0.text.hasPrefix("it's both of us") })
    }

    func testActionChoicesSendTheirAttachment() async throws {
        let teller = ScriptedStoryTeller(stories: DemoStories.all, typingDelay: .zero)
        var run = StoryRun(momentID: "lisbon")
        var first = try await teller.nextBeat(for: run, context: context("lisbon"))
        first.pickedChoice = 2
        run.beats = [first]
        XCTAssertNil(first.sentMessage, "an action isn't a text")
        let next = try await teller.nextBeat(for: run, context: context("lisbon"))
        XCTAssertEqual(next.reactions.first, SimulatedMessage(senderID: nil, text: "🍒🍒 on the table"))
    }

    func testChoiceQuotes() {
        XCTAssertEqual(StoryChoice(text: "“we're getting the 9:15”").sentText, "we're getting the 9:15")
        XCTAssertEqual(StoryChoice(text: "\"ok\"").sentText, "ok")
        XCTAssertNil(StoryChoice(text: "say nothing. send her the sunrise.").sentText)
    }
}

final class VoiceTraitTests: XCTestCase {
    func voice(_ id: String) -> VoiceProfile { DemoWorld.voices.first { $0.id == id }! }

    func testMayaBadgesMatchTheMockup() {
        let badges = voice("maya").badges
        XCTAssertEqual(Array(badges.prefix(5)), ["lowercase, always", "LMAOOO (3+ O's)", "texts in bursts of 4", "~6 words a text", "ALL CAPS = real panic"])
    }

    func testDadLearnedLinesMatchTheMockup() {
        XCTAssertEqual(voice("dad").learnedLines, [
            "Ends every text with a period.",
            "Signs off “- Dad.” Every time.",
            "One 👍 a month, max.",
            "Replies avg. 7 words, 3 hrs later.",
        ])
        XCTAssertEqual(voice("maya").summary, "lowercase, panics in bursts")
    }

    func testVoiceMatchRewardsTheRightVoice() {
        let maya = voice("maya")
        let likeMaya = VoiceMatcher.match(["the gate is CLOSED", "it says departed", "i'm on the floor"], to: maya)
        let likeDad = VoiceMatcher.match(["The gate is closed. - Dad", "I am on the floor. - Dad"], to: maya)
        XCTAssertGreaterThan(likeMaya.score, 0.8)
        XCTAssertGreaterThan(likeMaya.score, likeDad.score + 0.2)
        XCTAssertEqual(likeMaya.checks.map(\.label), ["lowercase", "bursts", "caps for panic"])
        XCTAssertTrue(likeMaya.checks.allSatisfy(\.passed))
        XCTAssertFalse(likeDad.checks.first!.passed)
    }
}

final class ModelEvolutionTests: XCTestCase {
    /// Records written by the first build must still load.
    func testOlderRecordsDecode() throws {
        let decoder = JSONDecoder()
        let person = try decoder.decode(Person.self, from: Data(#"{"id":"p","displayName":"Maya","handles":[],"chatIDs":[1],"isGroup":false,"color":"coral","messageCount":5,"included":true}"#.utf8))
        XCTAssertEqual(person.momentCount, 0)
        XCTAssertEqual(person.members, [])

        let moment = try decoder.decode(Moment.self, from: Data(#"{"id":"m","title":"T","titleIsProvisional":false,"date":0,"primaryPersonID":"p","personIDs":["p"],"tag":"trip","evidence":{"kind":"receipt"},"summary":"","messageCount":3,"playCount":0}"#.utf8))
        XCTAssertEqual(moment.chapterCount, 4)
        XCTAssertEqual(moment.evidence?.details, [:])

        let settings = try decoder.decode(AppSettings.self, from: Data(#"{"player":{"name":"Jules"}}"#.utf8))
        XCTAssertEqual(settings.player.name, "Jules")
        XCTAssertEqual(settings.storyModel, .cloud)
        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.routing, .standard)
    }

    func testMomentLabels() {
        let lisbon = DemoWorld.moments.first { $0.id == "lisbon" }!
        XCTAssertEqual(lisbon.durationLabel, "2 hrs 11 min")
        XCTAssertEqual(lisbon.lengthLabel, "4 chapters · ~12 min")
        XCTAssertEqual(lisbon.evidenceCount, 3)
        XCTAssertEqual(DemoWorld.people.first?.captionName, "Maya Okafor")
        XCTAssertEqual(DemoWorld.people[1].captionName, "Dad (Michael Rowe)")
    }
}

final class EngineEndingTests: XCTestCase {
    func testLastChoiceProducesTheEnding() async throws {
        let ending = """
        {"chapter_title": "names over the speaker", "reactions": [{"from": "Maya", "text": "I LOVE YOU"}],
         "narration": "Wheels up.", "messages": [], "choices": ["ignored"], "ends_story": true, "outcome": "you caught the 9:15"}
        """
        let transport = RecordingTransport(body: ["model": "claude-opus-5-5", "stop_reason": "end_turn", "content": [["type": "text", "text": ending]]])
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "k"]), transport: transport, onDevice: { nil })
        var run = StoryRun(momentID: "lisbon", chapterCount: 1)
        run.beats = [StoryBeat(chapter: 1, narration: "", messages: [], choices: [StoryChoice(text: "“go”")], endsChapter: true, pickedChoice: 0)]
        let maya = CastMember(person: DemoWorld.people[0], voice: nil)
        let context = StoryContext(moment: DemoWorld.moments[0], cast: [maya], notes: [], settings: DemoWorld.settings())

        let beat = try await engine.nextBeat(for: run, context: context)
        XCTAssertTrue(beat.endsStory)
        XCTAssertTrue(beat.choices.isEmpty)
        XCTAssertEqual(beat.chapter, 1)
        XCTAssertEqual(beat.outcome, "you caught the 9:15")
        XCTAssertEqual(beat.reactions.first?.senderID, "maya")

        let sent = try transport.sentBody()
        let messages = try XCTUnwrap(sent["messages"] as? [[String: Any]])
        XCTAssertTrue((messages.last?["content"] as? String)?.contains("last choice") == true)
    }

    func testOnDeviceChoiceNeedsTheModel() async {
        var settings = DemoWorld.settings()
        settings.storyModel = .onDevice
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "k"]), transport: RecordingTransport(body: [:]), onDevice: { nil })
        XCTAssertFalse(engine.canTell(with: settings))
        let context = StoryContext(moment: DemoWorld.moments[0], cast: [], notes: [], settings: settings)
        do {
            _ = try await engine.nextBeat(for: StoryRun(momentID: "lisbon"), context: context)
            XCTFail("expected on-device to be unavailable")
        } catch {
            XCTAssertEqual(error as? LLMError, .onDeviceUnavailable)
        }
    }

    func testLayeredTellerPrefersScripts() async throws {
        let engine = StoryEngine(secrets: InMemorySecretStore(), transport: RecordingTransport(body: [:]), onDevice: { nil })
        let teller = LayeredStoryTeller(scripted: ScriptedStoryTeller(stories: DemoStories.all, typingDelay: .zero), engine: engine, settings: DemoWorld.settings())
        XCTAssertTrue(teller.canTell("lisbon"))
        XCTAssertFalse(teller.canTell("a-real-moment"))
        let context = StoryContext(moment: DemoWorld.moments[0], cast: [], notes: [], settings: DemoWorld.settings())
        let beat = try await teller.nextBeat(for: StoryRun(momentID: "lisbon"), context: context)
        XCTAssertEqual(beat.chapterTitle, "alfama, one more song")
    }
}

final class WorldBuilderTests: XCTestCase {
    var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func makeChatDB(messages: Int) throws -> URL {
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
        let lines = ["the gate is CLOSED!!", "we missed the flight", "airport floor rn", "boarding was at 6", "lmaooo"]
        try db.transaction {
            for id in 0..<messages {
                let fromMe = id % 3 == 0
                // One dense session, then a quiet day, then another.
                let seconds = Int64(700_000_000 + id * 40 + (id >= messages / 2 ? 90_000 : 0))
                try db.run("INSERT INTO message VALUES (?, ?, ?, NULL, ?, ?, 0, 0, 0)", [
                    .int(Int64(id + 1)), .int(seconds * 1_000_000_000), .text(lines[id % lines.count]),
                    .int(fromMe ? 1 : 0), .int(fromMe ? 0 : 1),
                ])
                try db.run("INSERT INTO chat_message_join VALUES (1, ?)", [.int(Int64(id + 1))])
            }
        }
        return url
    }

    func testSurveyThenBuild() throws {
        let source = try makeChatDB(messages: 80)
        let store = try RecordStore(url: directory.appendingPathComponent("rerun.sqlite"))
        let builder = WorldBuilder(store: store, source: source)

        let people = try builder.survey()
        XCTAssertEqual(people.count, 1)
        XCTAssertEqual(people[0].displayName, "…0100")
        XCTAssertTrue(people[0].included)

        var phases: [WorldBuildProgress.Phase] = []
        let map = try builder.build(people: people) { phases.append($0.phase) }
        XCTAssertEqual(phases.first, .copying)
        XCTAssertEqual(phases.last, .drawing)
        XCTAssertTrue(phases.contains(.findingMoments))

        let moments = try store.all(Moment.self)
        XCTAssertEqual(moments.count, 2, "two sessions, both long enough")
        XCTAssertTrue(moments.allSatisfy { $0.tag == .trip && $0.evidence?.kind == .boardingPass })
        XCTAssertEqual(moments.first?.quote, "the gate is CLOSED!!")
        XCTAssertEqual(map.nodes.count, 2)
        XCTAssertEqual(try store.all(Person.self).first?.momentCount, 2)
        XCTAssertEqual(try store.all(VoiceProfile.self).count, 1)
        XCTAssertEqual(try store.get(AppSettings.self, id: AppSettings.singletonID)?.hasCompletedOnboarding, true)
    }

    func testNoConversations() throws {
        let source = try makeChatDB(messages: 10)
        let store = try RecordStore(url: directory.appendingPathComponent("rerun.sqlite"))
        XCTAssertThrowsError(try WorldBuilder(store: store, source: source).survey()) { error in
            XCTAssertEqual(error as? WorldBuildError, .noConversations)
        }
    }
}
