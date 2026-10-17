import Foundation

/// Jules's world from the design mockup, sticker for sticker. Shown before the
/// first Messages scan and used by previews and tests.
public enum DemoWorld {
    public static let player = PlayerProfile(name: "Jules", age: 29)

    public static let people: [Person] = [
        Person(id: "maya", displayName: "Maya", color: .coral, messageCount: 212),
        Person(id: "dad", displayName: "Dad", color: .blue, messageCount: 148),
        Person(id: "priya", displayName: "Priya", color: .leaf, messageCount: 131),
        Person(id: "theo", displayName: "Theo", color: .grape, messageCount: 96),
        Person(id: "ducks", displayName: "the ducks", isGroup: true, color: .sun, messageCount: 304),
    ]

    public static let moments: [Moment] = [
        Moment(
            id: "lisbon", title: "Lisbon: the missed flight", date: day(2024, 6, 14),
            primaryPersonID: "maya", tag: .trip, evidence: Evidence(.boardingPass), location: "Lisbon, PT",
            summary: "Last night ended at a fado bar in Alfama with “one more song.” Now it's 6:52 am, the gate is closed, and Maya is sitting on the airport floor. You have her bag. You have 18 minutes before she decides whose fault this is.",
            messageCount: 38, playCount: 3, lastPlayedAt: day(2026, 10, 12)
        ),
        Moment(id: "big-sur", title: "Big Sur, zero bars", date: day(2019, 8, 10), primaryPersonID: "maya", tag: .trip, messageCount: 61),
        Moment(id: "wedding-fight", title: "The wedding fight", date: day(2021, 3, 20), primaryPersonID: "maya", tag: .fight, messageCount: 84, playCount: 1),
        Moment(id: "fantasy-league", title: "Fantasy league mutiny", date: day(2023, 11, 5), primaryPersonID: "ducks", tag: .chaos, messageCount: 140, playCount: 2),
        Moment(
            id: "theo-30th", title: "Theo's 30th in Bushwick", date: day(2025, 10, 18), primaryPersonID: "ducks",
            personIDs: ["ducks", "theo"], tag: .celebration, evidence: Evidence(.ticketStub), messageCount: 97
        ),
        Moment(id: "voice-memos", title: "Dad discovers voice memos", date: day(2022, 2, 9), primaryPersonID: "dad", tag: .family, messageCount: 22, playCount: 1),
        Moment(
            id: "corolla", title: "The Corolla finally dies", date: day(2020, 7, 3), primaryPersonID: "dad",
            tag: .chaos, evidence: Evidence(.receipt, label: "tow receipt"), messageCount: 45, playCount: 1
        ),
        Moment(id: "dad-cooks", title: "Dad learns to cook", date: day(2023, 9, 17), primaryPersonID: "dad", tag: .family, messageCount: 31),
        Moment(id: "move-out", title: "Move-out day, apt 4B", date: day(2018, 5, 31), primaryPersonID: "priya", tag: .milestone, messageCount: 58, playCount: 1),
        Moment(
            id: "sushi", title: "The $214 sushi dinner", date: day(2024, 1, 19), primaryPersonID: "priya",
            tag: .food, evidence: Evidence(.receipt), location: "Sushi Nakazawa", messageCount: 27
        ),
        Moment(id: "theo-couch", title: "Three weeks on Theo's couch", date: day(2025, 4, 2), primaryPersonID: "theo", tag: .everyday, messageCount: 112, playCount: 1),
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

    public static func settings(now: Date = Date()) -> AppSettings {
        var settings = AppSettings(player: player)
        settings.lastScanAt = Calendar(identifier: .gregorian).date(bySettingHour: 9, minute: 14, second: 0, of: now)
        return settings
    }

    static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
