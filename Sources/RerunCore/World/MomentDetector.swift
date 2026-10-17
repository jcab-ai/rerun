import Foundation

/// A stretch of a conversation that looks like it mattered.
public struct MomentCandidate: Hashable, Sendable {
    public var range: Range<Int>
    public var start: Date
    public var end: Date
    public var tag: MomentTag
    public var score: Double
    public var firstRowID: Int64
    public var lastRowID: Int64

    public var messageCount: Int { range.count }
}

/// Finds moments in a thread without any model: split into sessions at long
/// silences, keep the dense and intense ones, and guess a scene tag from
/// keywords. Titles are placeholders until a model names them.
public struct MomentDetector {
    public var sessionGap: TimeInterval = 3 * 3600
    public var minMessages = 15
    public var maxMoments = 60

    static let lexicon: [MomentTag: [String]] = [
        .trip: ["flight", "airport", "gate", "boarding", "layover", "hotel", "airbnb", "passport", "landed", "train", "road trip", "check in", "tsa"],
        .romance: ["date", "kiss", "crush", "miss you", "love you", "babe", "cute", "❤️", "😍", "🥰", "first date"],
        .fight: ["sorry", "mad", "angry", "whatever", "upset", "hurt", "apologize", "unbelievable", "wtf", "can't believe you", "not okay"],
        .celebration: ["birthday", "bday", "party", "wedding", "graduation", "congrats", "congratulations", "cheers", "concert", "tickets", "game", "🎉"],
        .food: ["dinner", "lunch", "brunch", "restaurant", "sushi", "pizza", "reservation", "bill", "venmo", "tab", "omakase"],
        .family: ["mom", "dad", "grandma", "grandpa", "thanksgiving", "christmas", "home for", "family"],
        .chaos: ["help", "emergency", "broke down", "tow", "lost", "stolen", "missed", "locked out", "flooded", "omg"],
        .milestone: ["moving", "move out", "new job", "promotion", "lease", "keys", "engaged", "graduated", "first day"],
    ]

    public init() {}

    public func detect(in messages: [ChatMessage]) -> [MomentCandidate] {
        let candidates = sessions(in: messages).compactMap { range -> MomentCandidate? in
            guard range.count >= minMessages else { return nil }
            let slice = messages[range]
            let texts = slice.map(\.text)
            let (tag, hits) = classify(texts)
            let intensity = Double(texts.filter { $0.contains("!") || VoiceProfiler.hasShoutedWord($0) }.count) / Double(texts.count)
            let score = log(Double(range.count)) * (1 + intensity + 0.3 * Double(min(hits, 10)))
            return MomentCandidate(
                range: range,
                start: slice.first!.date,
                end: slice.last!.date,
                tag: tag,
                score: score,
                firstRowID: slice.first!.rowID,
                lastRowID: slice.last!.rowID
            )
        }
        return Array(candidates.sorted { $0.score > $1.score }.prefix(maxMoments))
            .sorted { $0.start < $1.start }
    }

    /// Runs of messages without a silence longer than `sessionGap`.
    public func sessions(in messages: [ChatMessage]) -> [Range<Int>] {
        guard !messages.isEmpty else { return [] }
        var ranges: [Range<Int>] = []
        var start = 0
        for index in 1..<messages.count where messages[index].date.timeIntervalSince(messages[index - 1].date) > sessionGap {
            ranges.append(start..<index)
            start = index
        }
        ranges.append(start..<messages.count)
        return ranges
    }

    /// The tag with the most keyword hits; `.everyday` when nothing stands out.
    public func classify(_ texts: [String]) -> (MomentTag, Int) {
        let words = Set(texts.flatMap(VoiceProfiler.words))
        let joined = texts.joined(separator: "\n").lowercased()
        var best: (MomentTag, Int) = (.everyday, 0)
        for tag in MomentTag.allCases {
            guard let keywords = Self.lexicon[tag] else { continue }
            let hits = keywords.reduce(0) { total, keyword in
                let isPhrase = keyword.contains(" ") || !keyword.allSatisfy(\.isLetter)
                return total + ((isPhrase ? joined.contains(keyword) : words.contains(keyword)) ? 1 : 0)
            }
            if hits > best.1 { best = (tag, hits) }
        }
        return best.1 >= 2 ? best : (.everyday, best.1)
    }

    public static func provisionalTitle(for tag: MomentTag, date: Date, with name: String) -> String {
        switch tag {
        case .trip: "The trip with \(name)"
        case .romance: "That night with \(name)"
        case .fight: "The fight with \(name)"
        case .celebration: "The party"
        case .food: "Dinner with \(name)"
        case .family: "Family stuff"
        case .chaos: "Total chaos"
        case .milestone: "The big day"
        case .everyday:
            "Just a \(DateFormatter.weekdayName.string(from: date))"
        }
    }
}

extension DateFormatter {
    static let weekdayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
