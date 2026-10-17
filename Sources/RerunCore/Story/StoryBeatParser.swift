import Foundation

/// Reads the model's JSON into a `StoryBeat`, tolerating code fences and
/// stray prose around the object.
public enum StoryBeatParser {
    public static func parse(_ text: String, chapter: Int, cast: [CastMember]) throws -> StoryBeat {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end,
              let object = try? JSONSerialization.jsonObject(with: Data(text[start...end].utf8)) as? [String: Any]
        else {
            throw LLMError.malformedResponse("no JSON object in the reply")
        }

        func texts(_ key: String) -> [SimulatedMessage] {
            (object[key] as? [[String: Any]] ?? []).compactMap { entry in
                guard let text = entry["text"] as? String, !text.isEmpty else { return nil }
                return SimulatedMessage(senderID: senderID(for: entry["from"] as? String, cast: cast), text: text)
            }
        }
        let messages = texts("messages")
        let reactions = texts("reactions")
        let endsStory = object["ends_story"] as? Bool ?? false
        let choices: [StoryChoice] = (object["choices"] as? [Any] ?? []).compactMap { choice in
            if let text = choice as? String { return StoryChoice(text: text) }
            if let text = (choice as? [String: Any])?["text"] as? String { return StoryChoice(text: text) }
            return nil
        }
        guard !messages.isEmpty || !choices.isEmpty || !reactions.isEmpty || endsStory else {
            throw LLMError.malformedResponse("the reply had no messages or choices")
        }

        return StoryBeat(
            chapter: chapter,
            chapterTitle: nonEmpty(object["chapter_title"]),
            reactions: reactions,
            narration: object["narration"] as? String ?? "",
            aside: nonEmpty(object["aside"]),
            clock: nonEmpty(object["clock"]),
            messages: messages,
            choices: endsStory ? [] : choices,
            endsChapter: object["ends_chapter"] as? Bool ?? endsStory,
            endsStory: endsStory,
            outcome: endsStory ? nonEmpty(object["outcome"]) : nil,
            nextSceneTag: (object["next_scene"] as? String).flatMap(MomentTag.init(rawValue:))
        )
    }

    /// The inverse, used to replay earlier beats to the model.
    public static func encode(_ beat: StoryBeat, cast: [CastMember]) -> String {
        let names = Dictionary(cast.map { ($0.person.id, $0.person.displayName) }, uniquingKeysWith: { a, _ in a })
        func texts(_ messages: [SimulatedMessage]) -> [[String: String]] {
            messages.map { ["from": $0.senderID.flatMap { names[$0] } ?? "you", "text": $0.text] }
        }
        var object: [String: Any] = [
            "narration": beat.narration,
            "reactions": texts(beat.reactions),
            "messages": texts(beat.messages),
            "choices": beat.choices.map(\.text),
            "ends_chapter": beat.endsChapter,
            "ends_story": beat.endsStory,
        ]
        if let title = beat.chapterTitle { object["chapter_title"] = title }
        if let aside = beat.aside { object["aside"] = aside }
        if let clock = beat.clock { object["clock"] = clock }
        if let outcome = beat.outcome { object["outcome"] = outcome }
        if let tag = beat.nextSceneTag { object["next_scene"] = tag.rawValue }
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    static func nonEmpty(_ value: Any?) -> String? {
        guard let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty else { return nil }
        return string
    }

    static func senderID(for name: String?, cast: [CastMember]) -> String? {
        guard let name = name?.trimmingCharacters(in: .whitespaces).lowercased(), !name.isEmpty else {
            return cast.first?.person.id
        }
        // The player's own lines.
        if name == "you" || name == "me" { return nil }
        let match = cast.first { member in
            member.person.id.lowercased() == name
                || member.person.displayName.lowercased() == name
                || member.person.shortName.lowercased() == name
        }
        return (match ?? cast.first)?.person.id
    }
}
