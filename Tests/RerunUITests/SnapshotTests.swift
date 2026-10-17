import AppKit
import RerunCore
@testable import RerunUI
import SwiftUI
import XCTest

/// Renders every screen offscreen at the mockup's 1200×780 window size so
/// they can be compared with design/reference. Set RERUN_SNAPSHOT_DIR to
/// write PNGs.
@MainActor
final class SnapshotTests: XCTestCase {
    func testBundledFontsRegister() {
        FontRegistry.registerBundledFonts()
        for name in ["Fredoka-Regular", "Fredoka-Medium", "Fredoka-SemiBold", "Fredoka-Bold", "Caveat-Medium", "Caveat-Bold", "SpaceMono-Regular", "SpaceMono-Bold"] {
            XCTAssertNotNil(NSFont(name: name, size: 12), "\(name) isn't registered")
        }
        XCTAssertNotNil(AppIcon.image)
    }

    // MARK: Onboarding

    func testWelcome() throws { try onboarding(.welcome, "01-welcome") }
    func testPrivacy() throws { try onboarding(.privacy, "02-privacy") }
    func testChoosePeople() throws { try onboarding(.choosePeople, "03-choose-people") }
    func testBuildingWorld() throws { try onboarding(.building, "04-building-world") }
    func testLocked() throws { try onboarding(.locked, "11a-locked") }
    func testNoConversations() throws { try onboarding(.noConversations, "11b-no-conversations") }

    private func onboarding(_ step: OnboardingStep, _ name: String) throws {
        let model = AppModel.sample()
        model.onboarding = step
        try snapshot(model, name)
    }

    // MARK: The world

    func testWorldMap() throws {
        try snapshot(AppModel.sample(), "05-world-map")
    }

    func testMomentDetail() throws {
        let model = AppModel.sample()
        model.screen = .moments
        model.openMomentID = "lisbon"
        try snapshot(model, "06-moment-detail")
    }

    func testMomentDetailReceipt() throws {
        let model = AppModel.sample()
        model.openMomentID = "corolla"
        try snapshot(model, "06b-moment-detail-receipt")
    }

    func testMomentDetailTicket() throws {
        let model = AppModel.sample()
        model.openMomentID = "theo-30th"
        try snapshot(model, "06c-moment-detail-ticket")
    }

    func testAddContext() throws {
        let model = AppModel.sample()
        model.openNotes(personID: "dad", momentID: "dad-cooks")
        try snapshot(model, "07-add-context")
    }

    func testStoryline() throws {
        let model = AppModel.sample()
        model.openStoryline("maya")
        try snapshot(model, "08-person-storyline")
    }

    func testPeople() throws {
        let model = AppModel.sample()
        model.screen = .people
        try snapshot(model, "08b-people")
    }

    func testMoments() throws {
        let model = AppModel.sample()
        model.screen = .moments
        try snapshot(model, "08c-moments")
    }

    func testSettings() throws {
        let model = AppModel.sample()
        model.screen = .settings
        try snapshot(model, "10-settings")
    }

    // MARK: Play

    func testPlayChoosing() async throws {
        let model = AppModel.sample()
        model.present(try await lisbon(picks: [0], phase: .choosing))
        try snapshot(model, "09-play")
    }

    func testPlayRevealed() async throws {
        let model = AppModel.sample()
        model.present(try await lisbon(picks: [0, 0], phase: .revealed))
        try snapshot(model, "09b-play-chapter-unlocked")
    }

    func testPlayEnded() async throws {
        let model = AppModel.sample()
        model.present(try await lisbon(picks: [0, 0, 0, 0], phase: .ended))
        try snapshot(model, "09c-play-ended")
    }

    func testChapterLost() async throws {
        let model = AppModel.sample()
        model.present(try await lisbon(picks: [0, 1], phase: .failed(.lostInTheMail("timeout"))))
        try snapshot(model, "11c-chapter-lost")
    }

    /// A Lisbon playthrough with `picks` made. `.revealed` holds the next beat
    /// as pending; `.ended` includes the ending; other phases stop at the
    /// beat after the last pick.
    private func lisbon(picks: [Int], phase: PlaySession.Phase) async throws -> PlaySession {
        let moment = DemoWorld.moments.first { $0.id == "lisbon" }!
        let maya = DemoWorld.people.first { $0.id == "maya" }!
        let context = StoryContext(
            moment: moment,
            cast: [CastMember(person: maya, voice: DemoWorld.voices.first { $0.id == "maya" })],
            notes: [],
            settings: DemoWorld.settings()
        )
        let teller = ScriptedStoryTeller(stories: DemoStories.all, typingDelay: .zero)
        var run = StoryRun(momentID: "lisbon", chapterCount: 4)
        var pending: StoryBeat?
        run.beats.append(try await teller.nextBeat(for: run, context: context))
        for (index, pick) in picks.enumerated() {
            run.beats[run.beats.count - 1].pickedChoice = pick
            let next = try await teller.nextBeat(for: run, context: context)
            if phase == .revealed && index == picks.count - 1 {
                pending = next
            } else if case .failed = phase, index == picks.count - 1 {
                break
            } else {
                run.beats.append(next)
            }
        }
        return PlaySession(moment: moment, context: context, run: run, phase: phase, pending: pending)
    }

    // MARK: Rendering

    private func snapshot(_ model: AppModel, _ name: String) throws {
        FontRegistry.registerBundledFonts()
        let renderer = ImageRenderer(content: RootView()
            .environmentObject(model)
            .environment(\.isRenderingSnapshot, true)
            .frame(width: Tokens.Metrics.windowWidth, height: Tokens.Metrics.windowHeight))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage, "nothing rendered for \(name)")
        XCTAssertEqual(image.width, Int(Tokens.Metrics.windowWidth))

        guard let directory = ProcessInfo.processInfo.environment["RERUN_SNAPSHOT_DIR"] else { return }
        let png = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try png.write(to: url)
    }
}
