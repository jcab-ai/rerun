import Foundation

public enum StoryStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case straightFromTexts, mostlyTrue, soapOpera

    public var label: String {
        switch self {
        case .straightFromTexts: "straight from the texts"
        case .mostlyTrue: "mostly true"
        case .soapOpera: "full soap opera"
        }
    }
}

/// Everything rerun is allowed to do. Stored locally with the rest of the world.
public struct AppSettings: StoredRecord, Hashable, Sendable {
    public static let table = "settings"
    public static let singletonID = "settings"

    public var id: String = AppSettings.singletonID
    public var player: PlayerProfile
    public var storyStyle: StoryStyle
    public var offLimitsTopics: [String]
    public var neverInventBreakupsOrDeaths: Bool
    /// Include a handful of each person's real (short) texts as voice examples in prompts.
    public var shareVoiceExamples: Bool
    /// Include the moment's own texts (capped) so the story starts from what really happened.
    public var shareMomentExcerpt: Bool
    public var routing: RoutingTable
    public var lastScanAt: Date?

    public init(
        player: PlayerProfile = PlayerProfile(name: "you"),
        storyStyle: StoryStyle = .mostlyTrue,
        offLimitsTopics: [String] = [],
        neverInventBreakupsOrDeaths: Bool = true,
        shareVoiceExamples: Bool = true,
        shareMomentExcerpt: Bool = true,
        routing: RoutingTable = .standard,
        lastScanAt: Date? = nil
    ) {
        self.player = player
        self.storyStyle = storyStyle
        self.offLimitsTopics = offLimitsTopics
        self.neverInventBreakupsOrDeaths = neverInventBreakupsOrDeaths
        self.shareVoiceExamples = shareVoiceExamples
        self.shareMomentExcerpt = shareMomentExcerpt
        self.routing = routing
        self.lastScanAt = lastScanAt
    }
}
