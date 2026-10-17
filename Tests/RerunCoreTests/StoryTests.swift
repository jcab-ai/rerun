import XCTest
@testable import RerunCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ModelRouterTests: XCTestCase {
    let table = RoutingTable.standard

    func testRomanceGoesToGeminiWhenConfigured() {
        let router = ModelRouter(table: table, configured: [.anthropic, .gemini])
        XCTAssertEqual(router.route(for: .romance)?.route.provider, .gemini)
        XCTAssertEqual(router.route(for: .romance)?.reason, .tagRoute(.romance))
        XCTAssertEqual(router.route(for: .trip)?.route, ModelRoute(provider: .anthropic, model: "claude-opus-5-5"))
        XCTAssertEqual(router.route(for: .trip)?.reason, .fallback)
    }

    func testFallsBackWhenPreferredProviderHasNoKey() {
        let router = ModelRouter(table: table, configured: [.anthropic])
        XCTAssertEqual(router.route(for: .romance)?.route.provider, .anthropic)
        XCTAssertEqual(router.route(for: .romance)?.reason, .substituted(preferred: .gemini))
    }

    func testUsesWhateverIsConfigured() {
        XCTAssertEqual(ModelRouter(table: table, configured: [.openai]).route(for: .fight)?.route, ModelRoute(provider: .openai))
        XCTAssertNil(ModelRouter(table: table, configured: []).route(for: .fight))
    }

    func testRoutingTableCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(table)
        XCTAssertEqual(try JSONDecoder().decode(RoutingTable.self, from: data), table)
    }
}

final class RecordingTransport: HTTPTransport, @unchecked Sendable {
    var requests: [URLRequest] = []
    let body: [String: Any]
    let status: Int

    init(status: Int = 200, body: [String: Any]) {
        self.status = status
        self.body = body
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (try JSONSerialization.data(withJSONObject: body), response)
    }

    func sentBody() throws -> [String: Any] {
        try JSONSerialization.jsonObject(with: requests[0].httpBody!) as! [String: Any]
    }
}

final class StoryEngineTests: XCTestCase {
    let beatJSON = """
    ```json
    {"chapter_title": "gate 14", "narration": "6:52 am. Maya is on the floor by the window.",
     "aside": "she's typing like she's about to cry or laugh",
     "messages": [{"from": "Maya", "text": "the gate is CLOSED"}, {"from": "maya", "text": "where are you"}],
     "choices": ["we're getting the 9:15", "this is your fault", {"text": "say nothing. send her the sunrise."}],
     "ends_chapter": false, "next_scene": "romance"}
    ```
    """

    func context() -> StoryContext {
        let maya = DemoWorld.people[0]
        var voice = VoiceProfile(id: "maya", sampleCount: 212, lowercaseRate: 0.93, examples: ["lmaooo"])
        voice.laughs = ["lmaooo"]
        var settings = DemoWorld.settings()
        settings.offLimitsTopics = ["Maya's ex"]
        return StoryContext(
            moment: DemoWorld.moments[0],
            cast: [CastMember(person: maya, voice: voice)],
            notes: [ContextNote(subject: .person("maya"), body: "Maya is afraid of flying.")],
            settings: settings
        )
    }

    func testAnthropicTurn() async throws {
        let transport = RecordingTransport(body: [
            "model": "claude-opus-5-5", "stop_reason": "end_turn",
            "content": [["type": "text", "text": beatJSON]],
        ])
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "sk-test"]), transport: transport)
        let run = StoryRun(momentID: "lisbon")

        let beat = try await engine.nextBeat(for: run, context: context())

        XCTAssertEqual(beat.chapter, 1)
        XCTAssertEqual(beat.messages.map(\.senderID), ["maya", "maya"])
        XCTAssertEqual(beat.choices.map(\.text).last, "say nothing. send her the sunrise.")
        XCTAssertEqual(beat.nextSceneTag, .romance)
        XCTAssertEqual(beat.route, ModelRoute(provider: .anthropic, model: "claude-opus-5-5"))

        let request = transport.requests[0]
        XCTAssertEqual(request.url?.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "sk-test")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-beta"), "server-side-fallback-2026-07-01")
        let body = try transport.sentBody()
        XCTAssertEqual(body["model"] as? String, "claude-opus-5-5")
        XCTAssertEqual(body["fallbacks"] as? String, "default")
        XCTAssertNil(body["temperature"])
        let system = try XCTUnwrap(body["system"] as? String)
        XCTAssertTrue(system.contains("Maya is afraid of flying."))
        XCTAssertTrue(system.contains("Maya's ex"))
        XCTAssertTrue(system.contains("\"lmaooo\""))
        XCTAssertTrue(system.contains("nothing is ever sent to the real people"))
    }

    func testNextSceneTagRoutesTheFollowingTurn() async throws {
        let transport = RecordingTransport(body: [
            "candidates": [["content": ["parts": [["text": beatJSON]]], "finishReason": "STOP"]],
        ])
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "a", .gemini: "g"]), transport: transport)
        var run = StoryRun(momentID: "lisbon")
        var first = try StoryBeatParser.parse(beatJSON, chapter: 1, cast: context().cast)
        first.pickedChoice = 0
        run.beats = [first]

        let beat = try await engine.nextBeat(for: run, context: context())

        XCTAssertEqual(beat.route?.provider, .gemini)
        XCTAssertEqual(transport.requests[0].value(forHTTPHeaderField: "x-goog-api-key"), "g")
        XCTAssertTrue(transport.requests[0].url!.absoluteString.hasSuffix("models/gemini-2.5-pro:generateContent"))
        let contents = try XCTUnwrap(transport.sentBody()["contents"] as? [[String: Any]])
        XCTAssertEqual(contents.map { $0["role"] as? String }, ["user", "model", "user"])
    }

    func testRefusalIsAnError() async {
        let transport = RecordingTransport(body: ["stop_reason": "refusal", "stop_details": ["category": "general_harms"], "content": []])
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "a"]), transport: transport)
        do {
            _ = try await engine.nextBeat(for: StoryRun(momentID: "lisbon"), context: context())
            XCTFail("expected a refusal")
        } catch {
            XCTAssertEqual(error as? LLMError, .refused(category: "general_harms"))
        }
    }

    func testNoKeysMeansNoRequest() async {
        let transport = RecordingTransport(body: [:])
        let engine = StoryEngine(secrets: InMemorySecretStore(), transport: transport)
        do {
            _ = try await engine.nextBeat(for: StoryRun(momentID: "lisbon"), context: context())
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? LLMError, .noProviderConfigured)
            XCTAssertTrue(transport.requests.isEmpty)
        }
    }

    func testTurnGateHook() async {
        struct Empty: TurnGate {
            func check(momentID: String) -> TurnGateDecision { .denied(reason: "out of energy", retryAt: nil) }
            func recordTurn(momentID: String, at date: Date) {}
        }
        let engine = StoryEngine(secrets: InMemorySecretStore([.anthropic: "a"]), gate: Empty(), transport: RecordingTransport(body: [:]))
        do {
            _ = try await engine.nextBeat(for: StoryRun(momentID: "lisbon"), context: context())
            XCTFail("expected the gate to deny")
        } catch {
            XCTAssertEqual(error as? StoryError, .turnDenied(reason: "out of energy", retryAt: nil))
        }
    }
}
