import Foundation

/// How someone texts, derived from their real messages. Used to keep generated
/// dialogue sounding like them, and shown as the handwritten caption next to
/// their name ("lowercase, panics in bursts").
public struct VoiceProfile: StoredRecord, Hashable, Sendable {
    public static let table = "voice_profiles"

    /// Same as the person's id.
    public var id: String
    public var sampleCount: Int

    // Casing & punctuation, as shares of their messages (0...1).
    public var lowercaseRate: Double
    public var shoutRate: Double
    public var terminalPeriodRate: Double
    public var exclamationRate: Double
    public var questionRate: Double
    public var ellipsisRate: Double
    /// Stretched words like "sooo" or "nooo".
    public var elongationRate: Double

    // Length & rhythm.
    public var medianLength: Int
    public var medianWords: Int
    /// Average number of messages they send in a row before you reply.
    public var burstSize: Double
    public var medianReplySeconds: Double?

    // Vocabulary.
    public var emojiPerMessage: Double
    public var topEmoji: [String]
    public var laughs: [String]
    public var slang: [String]
    /// A sign-off they put on most texts, e.g. "- Dad".
    public var signOff: String?

    /// A few short, real messages to anchor the model's imitation.
    public var examples: [String]

    public init(
        id: String,
        sampleCount: Int = 0,
        lowercaseRate: Double = 0,
        shoutRate: Double = 0,
        terminalPeriodRate: Double = 0,
        exclamationRate: Double = 0,
        questionRate: Double = 0,
        ellipsisRate: Double = 0,
        elongationRate: Double = 0,
        medianLength: Int = 0,
        medianWords: Int = 0,
        burstSize: Double = 1,
        medianReplySeconds: Double? = nil,
        emojiPerMessage: Double = 0,
        topEmoji: [String] = [],
        laughs: [String] = [],
        slang: [String] = [],
        signOff: String? = nil,
        examples: [String] = []
    ) {
        self.id = id
        self.sampleCount = sampleCount
        self.lowercaseRate = lowercaseRate
        self.shoutRate = shoutRate
        self.terminalPeriodRate = terminalPeriodRate
        self.exclamationRate = exclamationRate
        self.questionRate = questionRate
        self.ellipsisRate = ellipsisRate
        self.elongationRate = elongationRate
        self.medianLength = medianLength
        self.medianWords = medianWords
        self.burstSize = burstSize
        self.medianReplySeconds = medianReplySeconds
        self.emojiPerMessage = emojiPerMessage
        self.topEmoji = topEmoji
        self.laughs = laughs
        self.slang = slang
        self.signOff = signOff
        self.examples = examples
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        sampleCount = try c.decode(.sampleCount, default: 0)
        lowercaseRate = try c.decode(.lowercaseRate, default: 0)
        shoutRate = try c.decode(.shoutRate, default: 0)
        terminalPeriodRate = try c.decode(.terminalPeriodRate, default: 0)
        exclamationRate = try c.decode(.exclamationRate, default: 0)
        questionRate = try c.decode(.questionRate, default: 0)
        ellipsisRate = try c.decode(.ellipsisRate, default: 0)
        elongationRate = try c.decode(.elongationRate, default: 0)
        medianLength = try c.decode(.medianLength, default: 0)
        medianWords = try c.decode(.medianWords, default: 0)
        burstSize = try c.decode(.burstSize, default: 1)
        medianReplySeconds = try c.decodeIfPresent(Double.self, forKey: .medianReplySeconds)
        emojiPerMessage = try c.decode(.emojiPerMessage, default: 0)
        topEmoji = try c.decode(.topEmoji, default: [])
        laughs = try c.decode(.laughs, default: [])
        slang = try c.decode(.slang, default: [])
        signOff = try c.decodeIfPresent(String.self, forKey: .signOff)
        examples = try c.decode(.examples, default: [])
    }

    /// Short handwritten descriptors, most distinctive first.
    public var traits: [String] {
        var traits: [String] = []
        if lowercaseRate > 0.8 { traits.append("lowercase") }
        if terminalPeriodRate > 0.5 { traits.append("full stops. always.") }
        if signOff != nil { traits.append("signs every text") }
        if shoutRate > 0.08 && burstSize > 1.8 {
            traits.append("panics in bursts")
        } else if burstSize > 2.2 {
            traits.append("texts in bursts")
        } else if shoutRate > 0.15 {
            traits.append("CAPS when it matters")
        }
        if emojiPerMessage > 0.5 { traits.append("emoji every other text") }
        if elongationRate > 0.1 { traits.append("sooo many vowels") }
        if medianLength > 0 && medianLength < 18 { traits.append("short and quick") }
        if medianLength > 90 { traits.append("writes paragraphs") }
        if let reply = medianReplySeconds {
            if reply < 60 { traits.append("replies instantly") }
            if reply > 3 * 3600 { traits.append("replies hours later") }
        }
        return traits
    }

    /// "lowercase, panics in bursts"
    public var summary: String {
        traits.prefix(2).joined(separator: ", ")
    }

    /// Style instructions for a model, written as observations not orders.
    public func promptDescription(name: String, includeExamples: Bool) -> String {
        func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
        var lines = ["How \(name) texts (measured from \(sampleCount) real messages):"]
        lines.append("- all-lowercase in \(percent(lowercaseRate)) of messages; ALL-CAPS words in \(percent(shoutRate))")
        lines.append("- typical length ~\(medianLength) characters (~\(medianWords) words); sends ~\(String(format: "%.1f", burstSize)) messages in a row")
        lines.append("- ends with a period \(percent(terminalPeriodRate)), uses ! \(percent(exclamationRate)), ? \(percent(questionRate)), ellipses \(percent(ellipsisRate))")
        if emojiPerMessage > 0.05 {
            let favorites = topEmoji.isEmpty ? "" : " — favorites: \(topEmoji.joined(separator: " "))"
            lines.append("- \(String(format: "%.2f", emojiPerMessage)) emoji per message\(favorites)")
        } else {
            lines.append("- almost never uses emoji")
        }
        if !laughs.isEmpty { lines.append("- laughs like: \(laughs.joined(separator: ", "))") }
        if !slang.isEmpty { lines.append("- says: \(slang.joined(separator: ", "))") }
        if elongationRate > 0.05 { lines.append("- stretches words (\"sooo\", \"nooo\")") }
        if let signOff { lines.append("- signs off with \"\(signOff)\"") }
        if let reply = medianReplySeconds { lines.append("- usually replies after ~\(Self.describe(seconds: reply))") }
        if includeExamples && !examples.isEmpty {
            lines.append("Real examples:")
            lines += examples.map { "  \"\($0)\"" }
        }
        return lines.joined(separator: "\n")
    }

    /// Sticker-sized traits for the storyline header ("LMAOOO (3+ O's)").
    public var badges: [String] {
        var badges: [String] = []
        if lowercaseRate > 0.9 {
            badges.append("lowercase, always")
        } else if lowercaseRate > 0.65 {
            badges.append("mostly lowercase")
        }
        if terminalPeriodRate > 0.6 { badges.append("full stops. always.") }
        if let signOff { badges.append("signs off “\(signOff)”") }
        if let laugh = laughs.first {
            let upper = laugh.uppercased()
            if let last = upper.last, upper.reversed().prefix(while: { $0 == last }).count >= 3 {
                badges.append("\(upper) (3+ \(last)'s)")
            } else {
                badges.append(upper)
            }
        }
        if burstSize >= 1.8 { badges.append("texts in bursts of \(Int(burstSize.rounded()))") }
        if medianWords > 0 { badges.append("~\(medianWords) word\(medianWords == 1 ? "" : "s") a text") }
        if shoutRate > 0.05 { badges.append("ALL CAPS = real panic") }
        if emojiPerMessage > 0.5, let emoji = topEmoji.first { badges.append("\(emoji) in every other text") }
        if let reply = medianReplySeconds {
            if reply < 60 { badges.append("replies in seconds") }
            if reply > 3 * 3600 { badges.append("replies hours later") }
        }
        if let word = slang.first(where: { $0.count > 2 }) { badges.append("says “\(word)” a lot") }
        return Array(badges.prefix(6))
    }

    /// Plain sentences for "what the texts taught us".
    public var learnedLines: [String] {
        var lines: [String] = []
        if terminalPeriodRate > 0.6 { lines.append("Ends every text with a period.") }
        if lowercaseRate > 0.9 { lines.append("Has never once used the shift key.") }
        if let signOff { lines.append("Signs off “\(signOff).” Every time.") }
        if shoutRate > 0.08 { lines.append("Saves ALL CAPS for real emergencies.") }
        if burstSize > 2.5 { lines.append("Sends \(Int(burstSize.rounded())) texts where one would do.") }
        if let laugh = laughs.first { lines.append("Laughs in “\(laugh)”.") }
        if emojiPerMessage < 0.03 {
            lines.append(topEmoji.first.map { "One \($0) a month, max." } ?? "Has never sent an emoji.")
        } else if emojiPerMessage > 0.5, let emoji = topEmoji.first {
            lines.append("Emoji in almost every text — mostly \(emoji).")
        }
        if let reply = medianReplySeconds, medianWords > 0 {
            lines.append("Replies avg. \(medianWords) words, \(Self.describeShort(seconds: reply)) later.")
        }
        return Array(lines.prefix(4))
    }

    static func describeShort(seconds: Double) -> String {
        switch seconds {
        case ..<90: "\(Int(seconds)) sec"
        case ..<5400: "\(Int((seconds / 60).rounded())) min"
        default: "\(Int((seconds / 3600).rounded())) hrs"
        }
    }

    static func describe(seconds: Double) -> String {
        switch seconds {
        case ..<90: "\(Int(seconds)) seconds"
        case ..<5400: "\(Int((seconds / 60).rounded())) minutes"
        default: "\(Int((seconds / 3600).rounded())) hours"
        }
    }
}
