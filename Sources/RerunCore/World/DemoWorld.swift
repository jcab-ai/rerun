import Foundation

/// Jules's world from the design mockup, sticker for sticker. Shown before the
/// first Messages scan and used by previews and tests.
public enum DemoWorld {
    public static let player = PlayerProfile(name: "Jules", age: 29)

    public static let people: [Person] = [
        Person(
            id: "maya", displayName: "Maya", fullName: "Maya Okafor", relationship: "best friend · since sophomore year",
            color: .coral, messageCount: 18_204, momentCount: 212, since: day(2017, 9, 12)
        ),
        Person(
            id: "dad", displayName: "Dad", fullName: "Michael Rowe", relationship: "dad · first text in 2017",
            color: .blue, messageCount: 3_112, momentCount: 148, since: day(2017, 3, 1)
        ),
        Person(
            id: "priya", displayName: "Priya", fullName: "Priya Raman", relationship: "roommate, apt 4B · 2014–2018",
            color: .leaf, messageCount: 9_870, momentCount: 131, since: day(2017, 6, 4)
        ),
        Person(
            id: "theo", displayName: "Theo", fullName: "Theo Albright", relationship: "college roommate · professional couch owner",
            color: .grape, messageCount: 6_455, momentCount: 96, since: day(2017, 8, 20)
        ),
        Person(
            id: "ducks", displayName: "the ducks", relationship: "group chat · 5 people · est. 2018",
            isGroup: true, members: ["Theo", "Rafa", "Ana", "Kev"],
            color: .sun, messageCount: 41_337, momentCount: 304, since: day(2018, 2, 2)
        ),
        Person(id: "sam", displayName: "Sam", relationship: "work friend", color: .berry, messageCount: 2_210, momentCount: 58, included: false),
        Person(id: "mom", displayName: "Mom", relationship: "mostly sends “call me”", color: .slate, messageCount: 340, momentCount: 9, included: false),
    ]

    public static let moments: [Moment] = [
        Moment(
            id: "lisbon", title: "Lisbon: the missed flight", date: day(2024, 6, 14, 6, 41), endDate: day(2024, 6, 14, 8, 52),
            primaryPersonID: "maya", tag: .trip,
            evidence: Evidence(.boardingPass, details: [
                .carrier: "ATLANTICA AIR", .from: "LIS", .to: "JFK", .flight: "AT 207", .date: "14JUN",
                .gate: "14", .boarding: "06:10", .seat: "23A", .passenger: "ROWE / JULES", .stamp: "MISSED",
            ]),
            evidenceSource: "from Maya's photos & your Wallet",
            photoCaption: "gate 14, 6:58am", quote: "you have my bag and not a time machine", location: "Lisbon, PT",
            summary: "Last night ended at a fado bar in Alfama with “one more song.” Now it's 6:52 am, the gate is closed, and Maya is sitting on the airport floor. You have her bag. You have 18 minutes before she decides whose fault this is.",
            messageCount: 38, chapterCount: 4, playCount: 3, lastPlayedAt: day(2026, 10, 12), lastOutcome: "you caught the 9:15"
        ),
        Moment(
            id: "big-sur", title: "Big Sur, zero bars", tagline: "61 msgs, 3 delivered", date: day(2019, 8, 10, 15, 2), endDate: day(2019, 8, 10, 21, 40),
            primaryPersonID: "maya", tag: .trip, photoCaption: "bixby bridge, no signal", quote: "the vibes are correct", location: "Big Sur, CA",
            summary: "Highway 1, a screenshot of the wrong map, and a campsite booked for the wrong year. Maya is navigating by vibes. The vibes are, technically, correct.",
            messageCount: 61, chapterCount: 2
        ),
        Moment(
            id: "wedding-fight", title: "The wedding fight", tagline: "the quiet month", stat: "23 days, no texts",
            date: day(2021, 3, 20, 23, 10), endDate: day(2021, 4, 12, 9, 3),
            primaryPersonID: "maya", tag: .fight, quote: "don't come out here", location: "Hudson Valley, NY",
            summary: "Her cousin's wedding. Your toast had one joke too many, and Maya walked out of the tent. Then: twenty-three days of nothing, and a dog that looked like your toast.",
            messageCount: 84, chapterCount: 2, playCount: 1, lastPlayedAt: day(2026, 9, 2), lastOutcome: "you said sorry first"
        ),
        Moment(
            id: "first-u-up", title: "The first “u up?”", date: day(2017, 9, 14, 2, 14), endDate: day(2017, 9, 14, 3, 1),
            primaryPersonID: "maya", tag: .everyday, quote: "is ur dorm also on fire", location: "Hall C, 3rd floor",
            summary: "2:14 am, a fire alarm, and a number you don't have saved. Maya from stats wants to know if your dorm is also on fire.",
            messageCount: 22, chapterCount: 1
        ),
        Moment(
            id: "berlin", title: "Visiting her new job in Berlin", date: day(2025, 10, 2, 8, 30), endDate: day(2025, 10, 5, 18, 0),
            primaryPersonID: "maya", tag: .trip,
            evidence: Evidence(.receipt, label: "train ticket", details: [.merchant: "BER HBF · DB", .date: "02.OCT.25"], items: [
                EvidenceItem("ICE 1007 → München"), EvidenceItem("1 adult", "€39.90"),
            ]),
            location: "Berlin, DE",
            summary: "Maya's first week at the new job, a late German train, and one very sad pretzel.",
            messageCount: 47, chapterCount: 1
        ),
        Moment(
            id: "fantasy-league", title: "Fantasy league mutiny", date: day(2023, 11, 5, 8, 0), endDate: day(2023, 11, 5, 22, 30),
            primaryPersonID: "ducks", tag: .chaos, quote: "trust the process", location: "the ducks group chat",
            summary: "Kev traded his whole roster for a kicker. The ducks have opinions, two polls, and a gif of a duck.",
            messageCount: 140, chapterCount: 2, playCount: 2, lastPlayedAt: day(2026, 8, 30), lastOutcome: "you overthrew Kev"
        ),
        Moment(
            id: "theo-30th", title: "Theo's 30th in Bushwick", date: day(2025, 10, 18, 18, 30), endDate: day(2025, 10, 19, 1, 45),
            primaryPersonID: "ducks", personIDs: ["ducks", "theo"], tag: .celebration,
            evidence: Evidence(.ticketStub, details: [.event: "Theo's 3OTH", .section: "WAREHOUSE", .row: "GA", .date: "10/18/25"]),
            evidenceSource: "from the ducks' shared album",
            photoCaption: "the 3OTH cake", quote: "who made the 3OTH cake. i love it", location: "Bushwick, Brooklyn",
            summary: "A surprise party Theo definitely knows about, a warehouse in Bushwick, and a cake you were in charge of. You are not a cake person.",
            messageCount: 97, chapterCount: 2
        ),
        Moment(
            id: "voice-memos", title: "Dad discovers voice memos", date: day(2022, 2, 9, 18, 40), endDate: day(2022, 2, 9, 19, 30),
            primaryPersonID: "dad", tag: .family,
            evidence: Evidence(.voiceMemo, details: [.duration: "0:47", .caption: "Dad — bird feeder"]),
            quote: "Was that sent. - Dad", location: "Dad's kitchen",
            summary: "Dad has found the voice memo button, and he will not be putting it back. Forty-seven seconds, mostly about a cardinal.",
            messageCount: 22, chapterCount: 2, playCount: 1, lastPlayedAt: day(2026, 7, 4), lastOutcome: "you called him back"
        ),
        Moment(
            id: "corolla", title: "The Corolla finally dies", date: day(2020, 7, 3, 15, 5), endDate: day(2020, 7, 3, 17, 50),
            primaryPersonID: "dad", tag: .chaos,
            evidence: Evidence(.receipt, label: "tow receipt", details: [.merchant: "RT 9 TOWING & RECOVERY", .total: "142.50", .date: "07/03/20 · 4:41 PM", .stamp: "PAID"], items: [
                EvidenceItem("tow, 11 mi", "120.00"), EvidenceItem("after-hours", "21.00"), EvidenceItem("root beer x2", "1.50"),
            ]),
            quote: "She had a good run. - Dad", location: "Route 9 shoulder",
            summary: "The Corolla, 238,000 miles, stops on the shoulder of Route 9 for the last time. Dad is calm. Dad is too calm.",
            messageCount: 45, chapterCount: 2, playCount: 1, lastPlayedAt: day(2026, 6, 1), lastOutcome: "you split a root beer with Dad"
        ),
        Moment(
            id: "dad-cooks", title: "Dad learns to cook", tagline: "surgery week", date: day(2023, 9, 17, 17, 15), endDate: day(2023, 9, 17, 20, 0),
            primaryPersonID: "dad", tag: .family, photoCaption: "structurally, a lasagna", quote: "Very boiled. - Dad", location: "home",
            summary: "Mom is recovering. Dad, who has never made anything that wasn't toast, has decided on lasagna. It is not about the hospital. It's about him being so proud.",
            messageCount: 31, chapterCount: 2
        ),
        Moment(
            id: "move-out", title: "Move-out day, apt 4B", date: day(2018, 5, 31, 10, 10), endDate: day(2018, 5, 31, 12, 30),
            primaryPersonID: "priya", tag: .milestone, photoCaption: "two idiots on a floor", quote: "it's giving schrödinger ✨", location: "apt 4B",
            summary: "The landlord is coming at noon. The couch does not fit through the door it came in through. Four years in apartment 4B, ending sideways.",
            messageCount: 58, chapterCount: 2, playCount: 1, lastPlayedAt: day(2026, 5, 20), lastOutcome: "you left your initials in 4B"
        ),
        Moment(
            id: "sushi", title: "The $214 sushi dinner", date: day(2024, 1, 19, 20, 30), endDate: day(2024, 1, 19, 21, 41),
            primaryPersonID: "priya", tag: .food,
            evidence: Evidence(.receipt, details: [.merchant: "SUSHI NAKAZAWA", .total: "214.00", .date: "01/19/24 · 9:41 PM"], items: [
                EvidenceItem("omakase x2", "190.00"), EvidenceItem("sake", "24.00"),
            ]),
            evidenceSource: "from your Wallet",
            quote: "u didn't have to do this babe ✨", location: "Sushi Nakazawa, NYC",
            summary: "Priya's promotion dinner. You said “my treat” before you saw the menu. Twenty courses. One wooden box with a check in it.",
            messageCount: 27, chapterCount: 2
        ),
        Moment(
            id: "theo-couch", title: "Three weeks on Theo's couch", date: day(2025, 4, 2, 23, 30), endDate: day(2025, 4, 23, 13, 2),
            primaryPersonID: "theo", tag: .everyday, quote: "u ate my leftovers", location: "Theo's place",
            summary: "Between leases, on Theo's couch for “a couple days.” It has been a couple days times seven, and the leftovers are a sore subject.",
            messageCount: 112, chapterCount: 2, playCount: 1, lastPlayedAt: day(2026, 4, 9), lastOutcome: "you owe Theo a couch"
        ),
    ]

    public static let voices: [VoiceProfile] = [
        VoiceProfile(
            id: "maya", sampleCount: 9_412, lowercaseRate: 0.96, shoutRate: 0.11, terminalPeriodRate: 0.02,
            exclamationRate: 0.08, questionRate: 0.18, ellipsisRate: 0.03, elongationRate: 0.14,
            medianLength: 27, medianWords: 6, burstSize: 4.1, medianReplySeconds: 38,
            emojiPerMessage: 0.12, topEmoji: ["😭", "💀"], laughs: ["lmaooo"], slang: ["u", "ur", "omg"],
            examples: ["the gate is CLOSED", "ok hear me out", "u?? charm??", "i'm writing this down"]
        ),
        VoiceProfile(
            id: "dad", sampleCount: 1_480, lowercaseRate: 0, shoutRate: 0, terminalPeriodRate: 0.97,
            exclamationRate: 0.01, questionRate: 0.04, medianLength: 24, medianWords: 7, burstSize: 1.4,
            medianReplySeconds: 3 * 3600, emojiPerMessage: 0.01, topEmoji: ["👍"], signOff: "- Dad",
            examples: ["Ok. Call me when you land.", "Car stopped.", "She liked it."]
        ),
        VoiceProfile(
            id: "priya", sampleCount: 5_120, lowercaseRate: 0.71, shoutRate: 0.06, terminalPeriodRate: 0.03,
            exclamationRate: 0.22, questionRate: 0.2, medianLength: 31, medianWords: 7, burstSize: 2.6, medianReplySeconds: 95,
            emojiPerMessage: 0.94, topEmoji: ["😭", "✨", "💅"], laughs: ["omg"], slang: ["babe", "literally"],
            examples: ["babe the couch is STUCK 😭", "framing this ✨"]
        ),
        VoiceProfile(
            id: "theo", sampleCount: 3_330, lowercaseRate: 0.98, shoutRate: 0.04, terminalPeriodRate: 0,
            exclamationRate: 0.02, questionRate: 0.12, medianLength: 12, medianWords: 3, burstSize: 2.2, medianReplySeconds: 420,
            emojiPerMessage: 0.03, topEmoji: ["🦆"], laughs: ["lmao"], slang: ["bro", "dude", "bet"],
            examples: ["bro", "bet", "dude"]
        ),
        VoiceProfile(
            id: "ducks", sampleCount: 30_022, lowercaseRate: 0.83, shoutRate: 0.19, terminalPeriodRate: 0.01,
            exclamationRate: 0.09, questionRate: 0.1, elongationRate: 0.06, medianLength: 18, medianWords: 4, burstSize: 5.3,
            medianReplySeconds: 12, emojiPerMessage: 0.2, topEmoji: ["🦆", "😂"], laughs: ["lmao"], slang: ["bro"],
            examples: ["KEV", "explain urself", "trust the process"]
        ),
    ]

    public static let map = WorldMap(
        nodes: [
            MapNode(momentID: "lisbon", position: MapPoint(230, 140), control: MapPoint(330, 260), tilt: -5, width: 178),
            MapNode(momentID: "big-sur", position: MapPoint(95, 300), control: MapPoint(260, 330), tilt: 4),
            MapNode(momentID: "wedding-fight", position: MapPoint(360, 55), control: MapPoint(400, 160), tilt: 3, variant: .paper),
            MapNode(momentID: "fantasy-league", position: MapPoint(560, 60), control: MapPoint(540, 180), tilt: -3, width: 160),
            MapNode(momentID: "theo-30th", position: MapPoint(760, 110), control: MapPoint(660, 220), tilt: 6, width: 160),
            MapNode(momentID: "voice-memos", position: MapPoint(880, 260), control: MapPoint(720, 280), tilt: -4),
            MapNode(momentID: "corolla", position: MapPoint(860, 430), control: MapPoint(700, 400), tilt: 5),
            MapNode(momentID: "dad-cooks", position: MapPoint(740, 580), control: MapPoint(640, 480), tilt: -2, variant: .paper),
            MapNode(momentID: "move-out", position: MapPoint(540, 620), control: MapPoint(530, 480), tilt: 4),
            MapNode(momentID: "sushi", position: MapPoint(330, 600), control: MapPoint(400, 480), tilt: -6),
            MapNode(momentID: "theo-couch", position: MapPoint(150, 500), control: MapPoint(300, 440), tilt: 3),
        ],
        hubs: [
            MapHub(position: MapPoint(390, 235), personID: "ducks", hiddenCount: 48),
            MapHub(position: MapPoint(615, 245), personID: "dad", hiddenCount: 31),
            MapHub(position: MapPoint(640, 420), personID: "priya", hiddenCount: 22),
            MapHub(position: MapPoint(395, 450), personID: "theo", hiddenCount: 17),
            MapHub(position: MapPoint(330, 345)),
            MapHub(position: MapPoint(660, 330)),
        ],
        links: [
            MapLink(fromMomentID: "lisbon", toMomentID: "big-sur", control: MapPoint(160, 200), tinted: true),
            MapLink(fromMomentID: "theo-30th", toMomentID: "voice-memos", control: MapPoint(840, 170)),
            MapLink(fromMomentID: "theo-couch", toMomentID: "sushi", control: MapPoint(240, 580)),
        ],
        momentCount: 412,
        since: day(2017, 3, 1)
    )

    public static let notes: [ContextNote] = [
        ContextNote(id: "note-dad-ok", subject: .person("dad"), body: "Dad's “Ok.” with a period isn't mad — that's just how he types. When he's actually upset he goes quiet and texts Theo instead.", createdAt: day(2026, 9, 1)),
        ContextNote(id: "note-dad-sunday", subject: .person("dad"), body: "He calls every Sunday at 7 even though he says he “doesn't do phones.”", createdAt: day(2026, 9, 1, 13)),
        ContextNote(id: "note-dad-cooks", subject: .moment("dad-cooks"), body: "For Mom's surgery week: don't make it about the hospital. Make it about him learning to cook for her. The lasagna was a disaster and he was so proud.", createdAt: day(2026, 9, 1, 14)),
        ContextNote(id: "note-maya-dramatic", subject: .person("maya"), body: "Maya hates being called dramatic. She's not dramatic, she's thorough.", createdAt: day(2026, 8, 12)),
    ]

    public static func settings(now: Date = Date()) -> AppSettings {
        var settings = AppSettings(player: player, offLimitsTopics: ["health stuff", "money", "Maya's ex"], hasCompletedOnboarding: true)
        settings.lastScanAt = Calendar(identifier: .gregorian).date(bySettingHour: 9, minute: 14, second: 0, of: now)
        return settings
    }

    static func day(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
