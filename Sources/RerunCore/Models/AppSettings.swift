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

/// Where stories get written.
public enum StoryModelChoice: String, Codable, CaseIterable, Hashable, Sendable {
    /// Apple's on-device model. Nothing leaves the Mac.
    case onDevice
    /// The routed cloud providers, with your API keys.
    case cloud

    public var label: String {
        switch self {
        case .onDevice: "on-device"
        case .cloud: "cloud"
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
    public var storyModel: StoryModelChoice
    public var offLimitsTopics: [String]
    public var neverInventBreakupsOrDeaths: Bool
    /// Include a handful of each person's real (short) texts as voice examples in prompts.
    public var shareVoiceExamples: Bool
    /// Include the moment's own texts (capped) so the story starts from what really happened.
    public var shareMomentExcerpt: Bool
    public var routing: RoutingTable
    public var lastScanAt: Date?
    public var hasCompletedOnboarding: Bool

    public init(
        player: PlayerProfile = PlayerProfile(name: "you"),
        storyStyle: StoryStyle = .mostlyTrue,
        storyModel: StoryModelChoice = .cloud,
        offLimitsTopics: [String] = [],
        neverInventBreakupsOrDeaths: Bool = true,
        shareVoiceExamples: Bool = true,
        shareMomentExcerpt: Bool = true,
        routing: RoutingTable = .standard,
        lastScanAt: Date? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.player = player
        self.storyStyle = storyStyle
        self.storyModel = storyModel
        self.offLimitsTopics = offLimitsTopics
        self.neverInventBreakupsOrDeaths = neverInventBreakupsOrDeaths
        self.shareVoiceExamples = shareVoiceExamples
        self.shareMomentExcerpt = shareMomentExcerpt
        self.routing = routing
        self.lastScanAt = lastScanAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings()
        player = try c.decode(.player, default: defaults.player)
        storyStyle = try c.decode(.storyStyle, default: defaults.storyStyle)
        storyModel = try c.decode(.storyModel, default: defaults.storyModel)
        offLimitsTopics = try c.decode(.offLimitsTopics, default: defaults.offLimitsTopics)
        neverInventBreakupsOrDeaths = try c.decode(.neverInventBreakupsOrDeaths, default: defaults.neverInventBreakupsOrDeaths)
        shareVoiceExamples = try c.decode(.shareVoiceExamples, default: defaults.shareVoiceExamples)
        shareMomentExcerpt = try c.decode(.shareMomentExcerpt, default: defaults.shareMomentExcerpt)
        routing = try c.decode(.routing, default: defaults.routing)
        lastScanAt = try c.decodeIfPresent(Date.self, forKey: .lastScanAt)
        hasCompletedOnboarding = try c.decode(.hasCompletedOnboarding, default: false)
    }
}
