import Foundation

/// Measures how a person texts from their side of a thread.
public struct VoiceProfiler {
    public var maxExamples = 6
    /// Gaps longer than this aren't "replies", they're new conversations.
    public var replyWindow: TimeInterval = 12 * 3600

    static let slangLexicon: Set<String> = [
        "ngl", "tbh", "fr", "idk", "rn", "omg", "bruh", "bro", "dude", "ya", "u", "ur", "k", "kk",
        "yea", "ye", "bet", "lowkey", "highkey", "deadass", "istg", "smh", "wyd", "hbu", "ty", "thx",
        "pls", "plz", "gonna", "wanna", "gotta", "cuz", "tho", "nvm", "imo", "af", "fam", "yall", "y'all",
    ]

    static let laughPattern = try! NSRegularExpression(
        pattern: #"\b(l+m+f*a+o+|l+o+l+|(?:ha){2,}h?|(?:he){2,}h?|ja(?:ja)+)\b"#,
        options: [.caseInsensitive]
    )

    public init() {}

    /// - Parameters:
    ///   - thread: the whole conversation, oldest first (needed for reply timing and bursts).
    ///   - isTheirs: which messages were written by the person being profiled.
    public func profile(id: String, thread: [ChatMessage], isTheirs: (ChatMessage) -> Bool) -> VoiceProfile {
        let theirs = thread.filter(isTheirs)
        guard !theirs.isEmpty else { return VoiceProfile(id: id) }
        let signOff = Self.signOff(theirs.map(\.text))
        // Measure the message itself, not the signature on the end of it.
        let texts = theirs.map { message in
            guard let signOff, message.text.hasSuffix(signOff) else { return message.text }
            return String(message.text.dropLast(signOff.count)).trimmingCharacters(in: .whitespaces)
        }
        let count = Double(texts.count)
        func rate(_ predicate: (String) -> Bool) -> Double {
            Double(texts.filter(predicate).count) / count
        }

        let withLetters = texts.filter { $0.contains(where: \.isLetter) }
        let lowercaseRate = withLetters.isEmpty ? 0 :
            Double(withLetters.filter { !$0.contains(where: \.isUppercase) }.count) / Double(withLetters.count)

        var emojiCounts: [String: Int] = [:]
        var laughCounts: [String: Int] = [:]
        var slangCounts: [String: Int] = [:]
        var emojiTotal = 0
        for text in texts {
            for character in text where Self.isEmoji(character) {
                emojiTotal += 1
                emojiCounts[String(character), default: 0] += 1
            }
            let range = NSRange(text.startIndex..., in: text)
            for match in Self.laughPattern.matches(in: text, range: range) {
                if let laughRange = Range(match.range, in: text) {
                    laughCounts[text[laughRange].lowercased(), default: 0] += 1
                }
            }
            for word in Self.words(text) where Self.slangLexicon.contains(word) {
                slangCounts[word, default: 0] += 1
            }
        }

        return VoiceProfile(
            id: id,
            sampleCount: texts.count,
            lowercaseRate: lowercaseRate,
            shoutRate: rate(Self.hasShoutedWord),
            terminalPeriodRate: rate { $0.hasSuffix(".") && !$0.hasSuffix("..") },
            exclamationRate: rate { $0.contains("!") },
            questionRate: rate { $0.contains("?") },
            ellipsisRate: rate { $0.contains("...") || $0.contains("…") },
            elongationRate: rate(Self.hasElongatedWord),
            medianLength: Self.median(texts.map(\.count)),
            medianWords: Self.median(texts.map { Self.words($0).count }),
            burstSize: Self.averageBurst(thread, isTheirs: isTheirs),
            medianReplySeconds: medianReply(thread, isTheirs: isTheirs),
            emojiPerMessage: Double(emojiTotal) / count,
            topEmoji: Self.top(emojiCounts, 3),
            laughs: Self.top(laughCounts, 2, minimum: 2),
            slang: Self.top(slangCounts, 5, minimum: 2),
            signOff: signOff,
            examples: examples(from: texts)
        )
    }

    static func isEmoji(_ character: Character) -> Bool {
        guard let first = character.unicodeScalars.first else { return false }
        if first.properties.isEmojiPresentation { return true }
        // Text-default symbols (like ❤) only count with the emoji variation selector.
        return first.properties.isEmoji && character.unicodeScalars.contains("\u{FE0F}")
    }

    static func words(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && $0 != "'" }
            .map(String.init)
    }

    static func hasShoutedWord(_ text: String) -> Bool {
        text.split { !$0.isLetter }.contains { word in
            word.count >= 3 && word.allSatisfy(\.isUppercase)
        }
    }

    static func hasElongatedWord(_ text: String) -> Bool {
        var previous: Character?
        var run = 1
        for character in text.lowercased() {
            if character == previous, character.isLetter {
                run += 1
                if run >= 3 { return true }
            } else {
                run = 1
            }
            previous = character
        }
        return false
    }

    static func median(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    static func averageBurst(_ thread: [ChatMessage], isTheirs: (ChatMessage) -> Bool) -> Double {
        var bursts: [Int] = []
        var current = 0
        for message in thread {
            if isTheirs(message) {
                current += 1
            } else if current > 0 {
                bursts.append(current)
                current = 0
            }
        }
        if current > 0 { bursts.append(current) }
        guard !bursts.isEmpty else { return 1 }
        return Double(bursts.reduce(0, +)) / Double(bursts.count)
    }

    func medianReply(_ thread: [ChatMessage], isTheirs: (ChatMessage) -> Bool) -> Double? {
        var gaps: [Double] = []
        for (previous, message) in zip(thread, thread.dropFirst()) where isTheirs(message) && previous.isFromMe {
            let gap = message.date.timeIntervalSince(previous.date)
            if gap >= 0 && gap < replyWindow { gaps.append(gap) }
        }
        guard !gaps.isEmpty else { return nil }
        return gaps.sorted()[gaps.count / 2]
    }

    static func top(_ counts: [String: Int], _ limit: Int, minimum: Int = 1) -> [String] {
        counts.filter { $0.value >= minimum }
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit)
            .map(\.key)
    }

    /// A trailing "- Name" style signature on at least a quarter of messages.
    static func signOff(_ texts: [String]) -> String? {
        var counts: [String: Int] = [:]
        for text in texts {
            guard let dash = text.range(of: " - ", options: .backwards) ?? text.range(of: " -", options: .backwards) else { continue }
            let tail = text[dash.upperBound...].trimmingCharacters(in: .whitespaces)
            guard !tail.isEmpty, tail.count <= 12, !tail.contains(" ") else { continue }
            counts["- " + tail, default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value }),
              Double(best.value) / Double(texts.count) >= 0.25 else { return nil }
        return best.key
    }

    /// Short, unremarkable messages spread across the history. Skips anything
    /// with links or long digit runs (addresses, phone numbers, codes).
    func examples(from texts: [String]) -> [String] {
        let candidates = texts.filter { text in
            (6...90).contains(text.count)
                && !text.contains("http")
                && !text.contains("www.")
                && text.range(of: #"\d{4,}"#, options: .regularExpression) == nil
        }
        var seen = Set<String>()
        let unique = candidates.filter { seen.insert($0.lowercased()).inserted }
        guard unique.count > maxExamples else { return unique }
        let stride = Double(unique.count) / Double(maxExamples)
        return (0..<maxExamples).map { unique[Int(Double($0) * stride)] }
    }
}
