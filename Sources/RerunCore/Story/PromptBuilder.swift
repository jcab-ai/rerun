import Foundation

/// Someone in a scene, with what we know about how they text.
public struct CastMember: Hashable, Sendable {
    public var person: Person
    public var voice: VoiceProfile?

    public init(person: Person, voice: VoiceProfile? = nil) {
        self.person = person
        self.voice = voice
    }
}

/// Everything a story turn is generated from.
public struct StoryContext: Sendable {
    public var moment: Moment
    public var cast: [CastMember]
    public var notes: [ContextNote]
    public var settings: AppSettings
    /// Real texts from the moment, oldest first.
    public var excerpt: [ChatMessage]

    public init(moment: Moment, cast: [CastMember], notes: [ContextNote], settings: AppSettings, excerpt: [ChatMessage] = []) {
        self.moment = moment
        self.cast = cast
        self.notes = notes
        self.settings = settings
        self.excerpt = excerpt
    }
}

/// Builds the prompts for a story turn. Only what's written here leaves the Mac.
public enum PromptBuilder {
    public static let maxExcerptMessages = 40

    /// - Parameter compact: the slim version for small on-device models
    ///   (no real-text excerpt, no example texts).
    public static func system(for context: StoryContext, run: StoryRun? = nil, compact: Bool = false) -> String {
        let moment = context.moment
        let settings = context.settings
        let player = settings.player.name
        var sections: [String] = []

        sections.append("""
        You are the story engine of rerun, a BitLife-style life sim that replays real moments from the player's \
        text history as an interactive story. The player is \(player). The story plays out as a simulated iMessage \
        thread inside the game; nothing is ever sent to the real people. Write the other characters' texts so they \
        sound exactly like them — match each person's casing, punctuation, length, emoji, slang and rhythm described below. \
        Never write \(player)'s texts for them except as choices.
        """)

        sections.append("Story style: " + styleInstruction(settings.storyStyle))

        var limits: [String] = []
        if !settings.offLimitsTopics.isEmpty {
            limits.append("Do not mention or allude to: \(settings.offLimitsTopics.joined(separator: "; ")).")
        }
        if settings.neverInventBreakupsOrDeaths {
            limits.append("Never invent breakups, deaths, or serious illness that the texts don't show.")
        }
        if !limits.isEmpty { sections.append("Limits:\n" + limits.joined(separator: "\n")) }

        let dateText = ISO8601DateFormatter.string(from: moment.date, timeZone: .current, formatOptions: [.withFullDate])
        var momentLines = ["The moment: \"\(moment.title)\" (\(dateText), \(moment.tag.rawValue))"]
        if let location = moment.location { momentLines.append("Where: \(location)") }
        if !moment.summary.isEmpty { momentLines.append("What happened: \(moment.summary)") }
        sections.append(momentLines.joined(separator: "\n"))

        let castText = context.cast.map { member in
            let name = member.person.displayName
            guard let voice = member.voice else { return "\(name): no texting history available." }
            return voice.promptDescription(name: name, includeExamples: settings.shareVoiceExamples && !compact)
        }
        if !castText.isEmpty { sections.append("Cast:\n" + castText.joined(separator: "\n\n")) }

        if !context.notes.isEmpty {
            let names = Dictionary(context.cast.map { ($0.person.id, $0.person.displayName) }, uniquingKeysWith: { a, _ in a })
            let lines = context.notes.map { note -> String in
                switch note.subject {
                case .moment: return "- (about this moment) \(note.body)"
                case .person(let id): return "- (about \(names[id] ?? "someone")) \(note.body)"
                }
            }
            sections.append("Context from \(player) that the texts don't show — treat as true:\n" + lines.joined(separator: "\n"))
        }

        if settings.shareMomentExcerpt && !compact && !context.excerpt.isEmpty {
            sections.append("The real texts from this moment (for grounding; don't quote them wholesale):\n" + excerptText(context))
        }

        let chapters = run?.chapterCount ?? moment.chapterCount
        sections.append("""
        The story has \(chapters) chapters. Each turn is one beat: it reacts to what \(player) just texted, sets the \
        next scene, and ends on a choice. End every chapter with "ends_chapter": true. On the last beat of chapter \
        \(chapters), set "ends_story": true, give no choices, and write the "outcome" — how it ended, past tense, \
        second person, under eight words (like "you caught the 9:15").
        """)

        let names = context.cast.map(\.person.displayName).joined(separator: "\", \"")
        sections.append("""
        Reply with only a JSON object, no prose around it:
        {
          "chapter_title": string,          // short, lowercase-friendly ("gate 14")
          "clock": string,                  // in-story time, like "6:52"
          "reactions": [{"from": "\(names)", "text": string}],  // 0-4 replies to what \(player) just texted
          "narration": string,              // 1-3 sentences of scene-setting, present tense, second person
          "aside": string,                  // a wry handwritten-style one-liner, optional
          "messages": [{"from": "\(names)", "text": string}],   // 1-6 incoming texts that open the scene
          "choices": [string, string, string],   // what \(player) could do; put texts they'd send in “curly quotes”
          "ends_chapter": boolean,
          "ends_story": boolean,
          "outcome": string,                // only when ends_story is true
          "next_scene": one of \(MomentTag.allCases.map(\.rawValue))
        }
        """)

        return sections.joined(separator: "\n\n")
    }

    /// The running conversation: earlier beats as the model's turns, the player's picks as user turns.
    public static func messages(for run: StoryRun, context: StoryContext) -> [LLMMessage] {
        var messages = [LLMMessage(.user, "Start chapter 1 of \(run.chapterCount).")]
        for beat in run.beats {
            messages.append(LLMMessage(.assistant, StoryBeatParser.encode(beat, cast: context.cast)))
            guard let picked = beat.pickedChoice, beat.choices.indices.contains(picked) else { break }
            let next = beat.endsChapter ? "Start chapter \(beat.chapter + 1) of \(run.chapterCount)." : "Continue."
            let pick = beat.choices[picked]
            let action = pick.sentText.map { "texts: \"\($0)\"" } ?? "chooses to: \(pick.text)"
            let final = beat.chapter >= run.chapterCount && beat.endsChapter ? "That was the last choice. Write the ending beat." : next
            messages.append(LLMMessage(.user, "\(context.settings.player.name) \(action). \(final)"))
        }
        return messages
    }

    static func styleInstruction(_ style: StoryStyle) -> String {
        switch style {
        case .straightFromTexts: "Stay as close to what the texts show as possible. Choices change small things, not facts."
        case .mostlyTrue: "Start from what really happened, then let choices take it somewhere plausible."
        case .soapOpera: "Start from what really happened, then go big: twists, coincidences, dramatic reveals — still in character."
        }
    }

    static func excerptText(_ context: StoryContext) -> String {
        let names = Dictionary(context.cast.flatMap { member in member.person.handles.map { ($0, member.person.displayName) } }, uniquingKeysWith: { a, _ in a })
        return context.excerpt.suffix(maxExcerptMessages).map { message in
            let sender = message.isFromMe ? context.settings.player.name : (message.senderHandle.flatMap { names[$0] } ?? context.cast.first?.person.displayName ?? "them")
            return "\(sender): \(message.text)"
        }.joined(separator: "\n")
    }
}
