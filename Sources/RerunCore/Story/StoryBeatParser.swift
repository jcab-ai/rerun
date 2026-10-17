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

        let messages: [SimulatedMessage] = (object["messages"] as? [[String: Any]] ?? []).compactMap { entry in
            guard let text = entry["text"] as? String, !text.isEmpty else { return nil }
            return SimulatedMessage(senderID: senderID(for: entry["from"] as? String, cast: cast), text: text)
        }
        let choices: [StoryChoice] = (object["choices"] as? [Any] ?? []).compactMap { choice in
            if let text = choice as? String { return StoryChoice(text: text) }
            if let text = (choice as? [String: Any])?["text"] as? String { return StoryChoice(text: text) }
            return nil
        }
        guard !messages.isEmpty || !choices.isEmpty else {
            throw LLMError.malformedResponse("the reply had no messages or choices")
        }

        return StoryBeat(
            chapter: chapter,
            chapterTitle: object["chapter_title"] as? String,
            narration: object["narration"] as? String ?? "",
            aside: (object["aside"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            messages: messages,
            choices: choices,
            endsChapter: object["ends_chapter"] as? Bool ?? false,
            nextSceneTag: (object["next_scene"] as? String).flatMap(MomentTag.init(rawValue:))
        )
    }

    /// The inverse, used to replay earlier beats to the model.
    public static func encode(_ beat: StoryBeat, cast: [CastMember]) -> String {
        let names = Dictionary(cast.map { ($0.person.id, $0.person.displayName) }, uniquingKeysWith: { a, _ in a })
        var object: [String: Any] = [
            "narration": beat.narration,
            "messages": beat.messages.map { ["from": $0.senderID.flatMap { names[$0] } ?? "you", "text": $0.text] },
            "choices": beat.choices.map(\.text),
            "ends_chapter": beat.endsChapter,
        ]
        if let title = beat.chapterTitle { object["chapter_title"] = title }
        if let aside = beat.aside { object["aside"] = aside }
        if let tag = beat.nextSceneTag { object["next_scene"] = tag.rawValue }
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    static func senderID(for name: String?, cast: [CastMember]) -> String? {
        guard let name = name?.trimmingCharacters(in: .whitespaces).lowercased(), !name.isEmpty, name != "you" else {
            return cast.first?.person.id
        }
        let match = cast.first { member in
            member.person.id.lowercased() == name
                || member.person.displayName.lowercased() == name
                || member.person.shortName.lowercased() == name
        }
        return (match ?? cast.first)?.person.id
    }
}
