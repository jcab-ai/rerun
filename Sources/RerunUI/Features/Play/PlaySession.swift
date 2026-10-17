import Foundation
import RerunCore
import SwiftUI

/// One playthrough on the play screen: asks the storyteller for beats, holds
/// the player's picks, and reveals replies before the next chapter starts.
@MainActor
public final class PlaySession: ObservableObject, Identifiable {
    public enum Phase: Equatable {
        /// Writing the first beat.
        case loading
        /// The current beat's choices are up.
        case choosing
        /// A choice was picked; the next beat is being written.
        case waiting
        /// The next beat is ready; its reactions are in the phone and the
        /// "chapter unlocked" bar is up.
        case revealed
        case ended
        case failed(Failure)
    }

    public enum Failure: Equatable {
        /// A generation error ("This chapter got lost in the mail").
        case lostInTheMail(String)
        /// No script and no model configured.
        case noStoryteller
        case onDeviceUnavailable
    }

    /// One row in the simulated phone.
    public enum PhoneItem: Hashable {
        case time(String)
        case bubble(SimulatedMessage)
        case receipt(String)
        case typing
    }

    public let id = UUID()
    public let moment: Moment
    public let context: StoryContext
    let teller: StoryTeller
    let onFinish: (StoryRun) -> Void

    @Published public private(set) var run: StoryRun
    @Published public private(set) var pending: StoryBeat?
    @Published public private(set) var phase: Phase = .loading
    private var task: Task<Void, Never>?

    init(moment: Moment, context: StoryContext, chapterCount: Int, teller: StoryTeller, onFinish: @escaping (StoryRun) -> Void) {
        self.moment = moment
        self.context = context
        self.teller = teller
        self.onFinish = onFinish
        self.run = StoryRun(momentID: moment.id, chapterCount: chapterCount)
    }

    /// For snapshots and previews: a session already part-way through.
    init(moment: Moment, context: StoryContext, run: StoryRun, phase: Phase, pending: StoryBeat? = nil) {
        self.moment = moment
        self.context = context
        self.teller = ScriptedStoryTeller(stories: [])
        self.onFinish = { _ in }
        self.run = run
        self.phase = phase
        self.pending = pending
    }

    public var current: StoryBeat? { run.beats.last }

    /// The person the scene is mostly with.
    public var lead: Person? { context.cast.first?.person }

    public func person(_ id: String?) -> Person? {
        guard let id else { return nil }
        return context.cast.first { $0.person.id == id }?.person
    }

    // MARK: Actions

    func start() {
        guard run.beats.isEmpty else { return }
        phase = .loading
        fetch()
    }

    public func pick(_ index: Int) {
        guard phase == .choosing, let last = run.beats.indices.last, run.beats[last].choices.indices.contains(index) else { return }
        run.beats[last].pickedChoice = index
        phase = .waiting
        fetch()
    }

    /// Takes the last pick back.
    public func pickAgain() {
        guard phase == .waiting || phase == .revealed, let last = run.beats.indices.last else { return }
        task?.cancel()
        run.beats[last].pickedChoice = nil
        pending = nil
        phase = .choosing
    }

    /// "continue →": the pending beat becomes the current one.
    public func continueStory() {
        guard phase == .revealed, let beat = pending else { return }
        run.beats.append(beat)
        pending = nil
        if beat.endsStory {
            run.finishedAt = Date()
            phase = .ended
            onFinish(run)
        } else {
            phase = .choosing
        }
    }

    public func retry() {
        phase = run.beats.isEmpty ? .loading : .waiting
        fetch()
    }

    func cancel() {
        task?.cancel()
    }

    private func fetch() {
        task?.cancel()
        let run = self.run
        task = Task { [teller, context] in
            do {
                let beat = try await teller.nextBeat(for: run, context: context)
                guard !Task.isCancelled else { return }
                if self.run.beats.isEmpty {
                    self.run.beats.append(beat)
                    self.phase = .choosing
                } else {
                    self.pending = beat
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { self.phase = .revealed }
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.phase = .failed(Self.failure(for: error))
            }
        }
    }

    static func failure(for error: Error) -> Failure {
        switch error {
        case StoryError.noStoryteller, LLMError.noProviderConfigured: .noStoryteller
        case LLMError.onDeviceUnavailable: .onDeviceUnavailable
        default: .lostInTheMail(String(describing: error))
        }
    }

    // MARK: What's on screen

    /// The phone's contents, oldest first.
    public var phoneItems: [PhoneItem] {
        var items: [PhoneItem] = []
        let day = DateFormatter.rerun("EEE, MMM d").string(from: moment.date)
        let firstClock = run.beats.first?.clock
        items.append(.time(firstClock.map { "\(day) · \($0)" } ?? day))
        for (index, beat) in run.beats.enumerated() {
            items += beat.reactions.map(PhoneItem.bubble)
            if index > 0, let clock = beat.clock, clock != run.beats[index - 1].clock {
                items.append(.time(clock))
            }
            items += beat.messages.map(PhoneItem.bubble)
            if let sent = beat.sentMessage { items.append(.bubble(sent)) }
        }
        switch phase {
        case .loading, .waiting:
            if run.beats.last?.sentMessage != nil { items.append(.receipt("Delivered")) }
            items.append(.typing)
        case .revealed:
            if run.beats.last?.sentMessage != nil { items.append(.receipt("Read \(pending?.clock ?? current?.clock ?? "")")) }
            items += (pending?.reactions ?? []).map(PhoneItem.bubble)
        default:
            break
        }
        return items
    }

    /// Everything the lead has "said" so far, for the voice match card.
    public var leadTexts: [String] {
        let shown = run.transcript + (phase == .revealed ? (pending?.reactions ?? []) : [])
        return shown.filter { !$0.isFromPlayer }.map(\.text)
    }

    public var voiceMatch: VoiceMatch? {
        guard let lead, let voice = context.cast.first(where: { $0.person.id == lead.id })?.voice, !leadTexts.isEmpty else { return nil }
        return VoiceMatcher.match(leadTexts, to: voice)
    }

    /// The beat whose scene is on the chapter card.
    public var sceneBeat: StoryBeat? {
        phase == .ended ? run.beats.last : current
    }
}
