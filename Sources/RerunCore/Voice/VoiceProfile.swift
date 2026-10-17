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
        self.burstSize = burstSize
        self.medianReplySeconds = medianReplySeconds
        self.emojiPerMessage = emojiPerMessage
        self.topEmoji = topEmoji
        self.laughs = laughs
        self.slang = slang
        self.signOff = signOff
        self.examples = examples
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
        lines.append("- typical length ~\(medianLength) characters; sends ~\(String(format: "%.1f", burstSize)) messages in a row")
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

    static func describe(seconds: Double) -> String {
        switch seconds {
        case ..<90: "\(Int(seconds)) seconds"
        case ..<5400: "\(Int((seconds / 60).rounded())) minutes"
        default: "\(Int((seconds / 3600).rounded())) hours"
        }
    }
}
