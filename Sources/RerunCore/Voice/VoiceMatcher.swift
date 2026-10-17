import Foundation

/// How closely generated texts match someone's real texting voice. Drives the
/// "94% sounds like her" card on the play screen.
public struct VoiceMatch: Hashable, Sendable {
    public struct Check: Hashable, Sendable {
        public var label: String
        public var passed: Bool
    }

    /// 0...1
    public var score: Double
    /// The person's most distinctive habits, and whether the texts kept them.
    public var checks: [Check]

    public var percent: Int { Int((score * 100).rounded()) }
}

public enum VoiceMatcher {
    /// Compares `texts` (one person's lines in a scene) against their profile.
    public static func match(_ texts: [String], to profile: VoiceProfile) -> VoiceMatch {
        let texts = texts.filter { !$0.isEmpty }
        guard !texts.isEmpty, profile.sampleCount > 0 else { return VoiceMatch(score: 0, checks: []) }
        let observed = VoiceProfiler().profile(
            id: profile.id,
            thread: texts.enumerated().map { ChatMessage(rowID: Int64($0.offset), date: Date(timeIntervalSince1970: Double($0.offset)), text: $0.element, isFromMe: false) },
            isTheirs: { _ in true }
        )

        // Rates compare directly; lengths compare on a log scale (6 vs 12 words is a big miss, 40 vs 46 isn't).
        func closeness(_ a: Double, _ b: Double) -> Double { 1 - min(1, abs(a - b)) }
        func lengthCloseness(_ a: Int, _ b: Int) -> Double {
            guard a > 0, b > 0 else { return 0.5 }
            return 1 - min(1, abs(log(Double(a) / Double(b))) / log(4))
        }
        let parts: [(Double, Double)] = [
            (closeness(observed.lowercaseRate, profile.lowercaseRate), 3),
            (closeness(observed.terminalPeriodRate, profile.terminalPeriodRate), 2),
            (closeness(min(1, observed.emojiPerMessage), min(1, profile.emojiPerMessage)), 1.5),
            (closeness(observed.shoutRate, profile.shoutRate), 1),
            (closeness(observed.exclamationRate, profile.exclamationRate), 0.5),
            (lengthCloseness(observed.medianWords, profile.medianWords), 2),
        ]
        let score = parts.reduce(0) { $0 + $1.0 * $1.1 } / parts.reduce(0) { $0 + $1.1 }

        var checks: [VoiceMatch.Check] = []
        if profile.lowercaseRate > 0.7 {
            checks.append(.init(label: "lowercase", passed: observed.lowercaseRate >= 0.6))
        }
        if profile.terminalPeriodRate > 0.6 {
            checks.append(.init(label: "full stops", passed: observed.terminalPeriodRate >= 0.5))
        }
        if let signOff = profile.signOff {
            checks.append(.init(label: "signs off", passed: texts.contains { $0.hasSuffix(signOff) }))
        }
        if profile.burstSize >= 1.8 {
            checks.append(.init(label: "bursts", passed: texts.count >= 2))
        }
        if profile.shoutRate > 0.05 {
            checks.append(.init(label: "caps for panic", passed: observed.shoutRate > 0))
        }
        if profile.emojiPerMessage > 0.5 {
            checks.append(.init(label: "emoji", passed: observed.emojiPerMessage > 0.2))
        }
        return VoiceMatch(score: score, checks: Array(checks.prefix(3)))
    }
}
