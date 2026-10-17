import Foundation

public struct MapPoint: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

/// How a moment sticker is drawn: filled with its person's color, or paper
/// with a colored border.
public enum NodeVariant: String, Codable, Hashable, Sendable {
    case filled, paper
}

/// A moment's sticker on the world map. Coordinates live in the fixed
/// `WorldMap.canvasSize` space with "you" at `WorldMap.center`.
public struct MapNode: Codable, Hashable, Sendable {
    public var momentID: String
    public var position: MapPoint
    /// Quadratic-curve control point for the line from "you".
    public var control: MapPoint
    public var tilt: Double
    public var width: Double
    public var variant: NodeVariant

    public init(momentID: String, position: MapPoint, control: MapPoint, tilt: Double, width: Double = 150, variant: NodeVariant = .filled) {
        self.momentID = momentID
        self.position = position
        self.control = control
        self.tilt = tilt
        self.width = width
        self.variant = variant
    }
}

/// A "+48" bubble: more moments with someone than fit on the map.
public struct MapHub: Codable, Hashable, Sendable {
    public var position: MapPoint
    public var personID: String?
    public var hiddenCount: Int?

    public init(position: MapPoint, personID: String? = nil, hiddenCount: Int? = nil) {
        self.position = position
        self.personID = personID
        self.hiddenCount = hiddenCount
    }

    public var radius: Double { hiddenCount == nil ? 4 : 5 }
}

/// A thin dashed line between two related moments.
public struct MapLink: Codable, Hashable, Sendable {
    public var fromMomentID: String
    public var toMomentID: String
    public var control: MapPoint
    /// Tinted with the person's color instead of ink.
    public var tinted: Bool

    public init(fromMomentID: String, toMomentID: String, control: MapPoint, tinted: Bool = false) {
        self.fromMomentID = fromMomentID
        self.toMomentID = toMomentID
        self.control = control
        self.tinted = tinted
    }
}

/// The persisted layout of the world map, so stickers stay put between launches.
public struct WorldMap: StoredRecord, Hashable, Sendable {
    public static let table = "world_map"
    public static let singletonID = "world"

    public static let canvasWidth = 980.0
    public static let canvasHeight = 680.0
    public static let center = MapPoint(490, 330)

    public var id: String = WorldMap.singletonID
    public var nodes: [MapNode]
    public var hubs: [MapHub]
    public var links: [MapLink]
    /// Every moment found, including the ones not shown as stickers.
    public var momentCount: Int
    /// The oldest text the world was built from.
    public var since: Date?

    public init(nodes: [MapNode], hubs: [MapHub] = [], links: [MapLink] = [], momentCount: Int? = nil, since: Date? = nil) {
        self.nodes = nodes
        self.hubs = hubs
        self.links = links
        self.momentCount = momentCount ?? nodes.count
        self.since = since
    }

    /// Whole years between `since` and `now`, at least 1.
    public func yearsSpanned(now: Date = Date()) -> Int {
        guard let since else { return 1 }
        let years = Calendar(identifier: .gregorian).dateComponents([.year], from: since, to: now).year ?? 0
        return max(1, years)
    }

    public func node(for momentID: String) -> MapNode? {
        nodes.first { $0.momentID == momentID }
    }
}
