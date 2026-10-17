import Foundation

/// Arranges moments around "you": each person gets a slice of the circle in
/// their color, their best moments become stickers, the rest collapse into a
/// "+N" hub. Deterministic, so the same world always lays out the same way.
public struct WorldLayout {
    public var maxPeople = 5
    public var maxNodesPerPerson = 3
    /// Where the first slice starts: upper left, like the mockup.
    public var startAngle = -150.0
    public var radiusX = 380.0
    public var radiusY = 270.0

    public init() {}

    public func layout(people: [Person], moments: [Moment], momentCount: Int? = nil, since: Date? = nil) -> WorldMap {
        let byPerson = Dictionary(grouping: moments, by: \.primaryPersonID)
        let ranked = people
            .filter { $0.included && !(byPerson[$0.id] ?? []).isEmpty }
            .sorted { $0.messageCount > $1.messageCount }
            .prefix(maxPeople)
        let featuredID = moments.filter { $0.lastPlayedAt != nil }.max { $0.lastPlayedAt! < $1.lastPlayedAt! }?.id

        let groups: [(person: Person, visible: [Moment], hidden: Int)] = ranked.map { person in
            let theirs = (byPerson[person.id] ?? []).sorted {
                ($0.id == featuredID ? 1 : 0, $0.playCount, $0.messageCount) > ($1.id == featuredID ? 1 : 0, $1.playCount, $1.messageCount)
            }
            let visible = Array(theirs.prefix(maxNodesPerPerson)).sorted { $0.date < $1.date }
            return (person, visible, theirs.count - visible.count)
        }
        let total = max(1, groups.reduce(0) { $0 + $1.visible.count })
        let center = WorldMap.center

        var nodes: [MapNode] = []
        var hubs: [MapHub] = []
        var links: [MapLink] = []
        var angle = startAngle

        for group in groups {
            let span = 360.0 * Double(group.visible.count) / Double(total)
            for (index, moment) in group.visible.enumerated() {
                let theta = (angle + span * (Double(index) + 0.5) / Double(group.visible.count)) * .pi / 180
                let ring = [0.78, 1.0, 0.88][index % 3]
                let featured = moment.id == featuredID
                let width = featured ? 178.0 : 150.0
                let position = MapPoint(
                    clamp(center.x + cos(theta) * radiusX * ring, width / 2 + 12, WorldMap.canvasWidth - width / 2 - 12),
                    clamp(center.y + sin(theta) * radiusY * ring, 44, WorldMap.canvasHeight - 44)
                )
                nodes.append(MapNode(
                    momentID: moment.id,
                    position: position,
                    control: bend(from: center, to: position, amount: index.isMultiple(of: 2) ? 0.16 : -0.16),
                    tilt: tilt(for: moment.id),
                    width: width,
                    variant: index == 2 ? .paper : .filled
                ))
            }

            if group.hidden > 0 {
                let theta = (angle + span / 2) * .pi / 180
                hubs.append(MapHub(
                    position: MapPoint(center.x + cos(theta) * radiusX * 0.42, center.y + sin(theta) * radiusY * 0.42),
                    personID: group.person.id,
                    hiddenCount: group.hidden
                ))
            }

            if group.visible.count >= 2, let a = nodes.first(where: { $0.momentID == group.visible[0].id }),
               let b = nodes.first(where: { $0.momentID == group.visible[1].id }) {
                links.append(MapLink(
                    fromMomentID: a.momentID,
                    toMomentID: b.momentID,
                    control: outward(midpointOf: a.position, b.position, from: center, by: 24),
                    tinted: group.visible.contains { $0.id == featuredID }
                ))
            }
            angle += span
        }

        return WorldMap(nodes: nodes, hubs: hubs, links: links, momentCount: momentCount ?? moments.count, since: since)
    }

    /// Control point for a gently curved line: the midpoint pushed sideways.
    func bend(from start: MapPoint, to end: MapPoint, amount: Double) -> MapPoint {
        let dx = end.x - start.x, dy = end.y - start.y
        return MapPoint(start.x + dx / 2 - dy * amount, start.y + dy / 2 + dx * amount)
    }

    func outward(midpointOf a: MapPoint, _ b: MapPoint, from center: MapPoint, by distance: Double) -> MapPoint {
        let mid = MapPoint((a.x + b.x) / 2, (a.y + b.y) / 2)
        let dx = mid.x - center.x, dy = mid.y - center.y
        let length = max(1, (dx * dx + dy * dy).squareRoot())
        return MapPoint(mid.x + dx / length * distance, mid.y + dy / length * distance)
    }

    /// A stable sticker tilt between 2° and 6°, either direction.
    func tilt(for id: String) -> Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in id.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        let magnitude = 2 + Double(hash % 5)
        return hash & 0x100 == 0 ? magnitude : -magnitude
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}
