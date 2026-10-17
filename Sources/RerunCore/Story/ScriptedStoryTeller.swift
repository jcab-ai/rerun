import Foundation

/// A text in a scripted scene. `from` is a person id, a group member's name,
/// or nil for the story's main character.
public struct ScriptedLine: Hashable, Sendable {
    public var from: String?
    public var text: String

    public init(_ text: String, from: String? = nil) {
        self.from = from
        self.text = text
    }
}

public struct ScriptedChoice: Hashable, Sendable {
    /// Quoted (“…”) when it's a text you send; plain when it's an action.
    public var text: String
    /// What an action sends, e.g. a photo ("📷 gate 14 at sunrise").
    public var sends: String?
    public var replies: [ScriptedLine]
    /// How the story ends if this is the last choice.
    public var outcome: String?

    public init(_ text: String, sends: String? = nil, replies: [ScriptedLine], outcome: String? = nil) {
        self.text = text
        self.sends = sends
        self.replies = replies
        self.outcome = outcome
    }
}

public struct ScriptedChapter: Hashable, Sendable {
    public var title: String
    public var clock: String
    public var narration: String
    public var aside: String?
    public var messages: [ScriptedLine]
    public var choices: [ScriptedChoice]

    public init(title: String, clock: String, narration: String, aside: String? = nil, messages: [ScriptedLine], choices: [ScriptedChoice]) {
        self.title = title
        self.clock = clock
        self.narration = narration
        self.aside = aside
        self.messages = messages
        self.choices = choices
    }
}

/// A hand-written branching story for a moment.
public struct ScriptedStory: Hashable, Sendable {
    public var momentID: String
    /// Who sends lines with no `from`.
    public var speakerID: String
    public var chapters: [ScriptedChapter]
    /// Shown above the final reactions.
    public var ending: String

    public init(momentID: String, speakerID: String, chapters: [ScriptedChapter], ending: String) {
        self.momentID = momentID
        self.speakerID = speakerID
        self.chapters = chapters
        self.ending = ending
    }
}

/// Plays hand-written stories: no model, no network, same beats as the engine.
public struct ScriptedStoryTeller: StoryTeller {
    let stories: [String: ScriptedStory]
    /// A pause so the "typing…" bubble has a moment to show.
    let typingDelay: Duration

    public init(stories: [ScriptedStory], typingDelay: Duration = .milliseconds(900)) {
        self.stories = Dictionary(stories.map { ($0.momentID, $0) }, uniquingKeysWith: { a, _ in a })
        self.typingDelay = typingDelay
    }

    public func canTell(_ momentID: String) -> Bool { stories[momentID] != nil }

    public func chapterCount(for momentID: String) -> Int? { stories[momentID]?.chapters.count }

    public func nextBeat(for run: StoryRun, context: StoryContext) async throws -> StoryBeat {
        guard let story = stories[run.momentID] else { throw StoryError.noStoryteller }
        if typingDelay > .zero { try await Task.sleep(for: typingDelay) }

        let index = run.beats.count
        let previousChoice: ScriptedChoice? = run.beats.last.flatMap { beat in
            guard let picked = beat.pickedChoice, index - 1 < story.chapters.count else { return nil }
            let choices = story.chapters[index - 1].choices
            return choices.indices.contains(picked) ? choices[picked] : nil
        }
        let reactions = previousChoice.map { choice in
            (choice.sends.map { [SimulatedMessage(senderID: nil, text: $0)] } ?? []) + messages(choice.replies, story)
        } ?? []

        guard index < story.chapters.count else {
            let last = story.chapters.last
            return StoryBeat(
                chapter: story.chapters.count,
                chapterTitle: last?.title,
                reactions: reactions,
                narration: story.ending,
                clock: last?.clock,
                messages: [],
                choices: [],
                endsChapter: true,
                endsStory: true,
                outcome: previousChoice?.outcome ?? "you lived it twice"
            )
        }

        let chapter = story.chapters[index]
        return StoryBeat(
            chapter: index + 1,
            chapterTitle: chapter.title,
            reactions: reactions,
            narration: chapter.narration,
            aside: chapter.aside,
            clock: chapter.clock,
            messages: messages(chapter.messages, story),
            choices: chapter.choices.map { StoryChoice(text: $0.text) },
            endsChapter: true
        )
    }

    private func messages(_ lines: [ScriptedLine], _ story: ScriptedStory) -> [SimulatedMessage] {
        lines.map { SimulatedMessage(senderID: $0.from ?? story.speakerID, text: $0.text) }
    }
}
