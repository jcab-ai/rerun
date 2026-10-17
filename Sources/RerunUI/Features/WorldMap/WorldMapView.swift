import RerunCore
import SwiftUI

/// Home: every moment as a sticker, strung to "you" in the middle.
struct WorldMapView: View {
    @EnvironmentObject private var model: AppModel
    @State private var zoom: CGFloat = 1
    @State private var pinchBase: CGFloat?
    @State private var pan: CGSize = .zero
    @State private var panBase: CGSize?

    private static let zoomRange: ClosedRange<CGFloat> = 0.6...1.8

    var body: some View {
        GeometryReader { geometry in
            let canvasOrigin = CGPoint(
                x: max(0, (geometry.size.width - WorldMap.canvasWidth) / 2),
                y: Tokens.Metrics.mapHeaderHeight + max(0, (geometry.size.height - Tokens.Metrics.mapHeaderHeight - WorldMap.canvasHeight) / 2)
            )
            ZStack(alignment: .topLeading) {
                DotGrid()

                WorldCanvas()
                    .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight)
                    .scaleEffect(zoom)
                    .offset(x: canvasOrigin.x + pan.width, y: canvasOrigin.y + pan.height)

                header
                    .frame(width: geometry.size.width, height: Tokens.Metrics.mapHeaderHeight)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(panGesture)
            .simultaneousGesture(pinchGesture)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: Tokens.Space.l) {
            Text("Your world")
                .textStyle(Tokens.Typography.screenTitle)
                .foregroundStyle(Tokens.Palette.ink)
            Text(stats)
                .textStyle(Tokens.Typography.handNote)
                .foregroundStyle(Tokens.Palette.pencil)
                .rotationEffect(.degrees(Tokens.Tilt.headerNote))
            Spacer(minLength: Tokens.Space.l)
            HStack(spacing: Tokens.Space.s) {
                FilterChip("everyone", isSelected: model.personFilter == nil) { model.personFilter = nil }
                ForEach(model.chipPeople) { person in
                    FilterChip(person.shortName, color: person.color.fill, isSelected: model.personFilter == person.id) {
                        model.personFilter = model.personFilter == person.id ? nil : person.id
                    }
                }
            }
            zoomControl
        }
        .padding(Tokens.Metrics.mapHeaderInsets)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: .infinity)
    }

    /// "412 moments, 9 years"
    private var stats: String {
        let years = model.map.yearsSpanned()
        return "\(model.map.momentCount) moments, \(years) year\(years == 1 ? "" : "s")"
    }

    private var zoomControl: some View {
        HStack(spacing: 0) {
            zoomButton("−", help: "Zoom out") { setZoom(zoom - 0.2) }
            Rectangle().fill(Tokens.Palette.ink).frame(width: Tokens.Stroke.chip)
            zoomButton("+", help: "Zoom in") { setZoom(zoom + 0.2) }
        }
        .fixedSize()
        .padding(Tokens.Stroke.chip)
        .background(RoundedRectangle(cornerRadius: Tokens.Radius.control).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.control).strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.chip))
    }

    private func zoomButton(_ label: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .textStyle(Tokens.Typography.monoBody)
                .foregroundStyle(Tokens.Palette.ink)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: Gestures

    private func setZoom(_ value: CGFloat) {
        withAnimation(.easeOut(duration: 0.18)) {
            zoom = min(max(value, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
            if zoom == 1 { pan = .zero }
        }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let base = panBase ?? pan
                panBase = base
                pan = CGSize(width: base.width + value.translation.width, height: base.height + value.translation.height)
            }
            .onEnded { _ in panBase = nil }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = pinchBase ?? zoom
                pinchBase = base
                zoom = min(max(base * value.magnification, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
            }
            .onEnded { _ in pinchBase = nil }
    }
}

/// The fixed 980×680 world: lines, hubs, stickers and "you", in map coordinates.
private struct WorldCanvas: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let featuredID = model.featuredMomentID
        ZStack(alignment: .topLeading) {
            MapLines(map: model.map, moments: model.moments, people: model.people, filter: model.personFilter)

            ForEach(Array(model.map.hubs.enumerated()), id: \.offset) { _, hub in
                if let count = hub.hiddenCount, let person = hub.personID.flatMap(model.person) {
                    CountTag("+\(count)", fill: person.color.fill, foreground: person.color.onFill)
                        .frame(width: 0, height: 0, alignment: .leading)
                        .position(x: hub.position.x + 10, y: hub.position.y)
                        .opacity(dimmed(personID: person.id) ? 0.25 : 1)
                }
            }

            ForEach(model.map.nodes, id: \.momentID) { node in
                if let moment = model.moment(node.momentID) {
                    MomentSticker(
                        moment: moment,
                        person: model.person(moment.primaryPersonID),
                        node: node,
                        isFeatured: moment.id == featuredID
                    ) {
                        model.openMomentID = moment.id
                    }
                    .position(x: node.position.x, y: node.position.y)
                    .opacity(model.isDimmed(moment) ? 0.25 : 1)
                    .zIndex(moment.id == featuredID ? 2 : 1)
                }
            }

            YouNode(player: model.settings.player)
                .position(x: WorldMap.center.x, y: WorldMap.center.y)
                .zIndex(3)

            MapLegend()
                .padding(.trailing, 20)
                .padding(.bottom, 18)
                .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight, alignment: .bottomTrailing)
                .zIndex(3)
        }
        .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight, alignment: .topLeading)
        .animation(.easeOut(duration: 0.2), value: model.personFilter)
    }

    private func dimmed(personID: String) -> Bool {
        model.personFilter.map { $0 != personID } ?? false
    }
}

/// Curved lines from "you" to each sticker (solid once played, dotted before),
/// thin dashed links between related moments, and the hub dots.
private struct MapLines: View {
    let map: WorldMap
    let moments: [Moment]
    let people: [Person]
    let filter: String?

    var body: some View {
        Canvas { context, _ in
            let momentsByID = Dictionary(moments.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let peopleByID = Dictionary(people.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let center = CGPoint(map: WorldMap.center)

            for node in map.nodes {
                guard let moment = momentsByID[node.momentID] else { continue }
                var path = Path()
                path.move(to: center)
                path.addQuadCurve(to: CGPoint(map: node.position), control: CGPoint(map: node.control))
                let color = peopleByID[moment.primaryPersonID]?.color.line ?? Tokens.Palette.ink
                let style = StrokeStyle(
                    lineWidth: Tokens.Stroke.edge,
                    lineCap: .round,
                    dash: moment.hasBeenPlayed ? [] : [2, 7]
                )
                context.stroke(path, with: .color(color.opacity(dimmed(moment) ? 0.25 : 1)), style: style)
            }

            for link in map.links {
                guard let from = map.node(for: link.fromMomentID), let to = map.node(for: link.toMomentID) else { continue }
                var path = Path()
                path.move(to: CGPoint(map: from.position))
                path.addQuadCurve(to: CGPoint(map: to.position), control: CGPoint(map: link.control))
                let person = momentsByID[link.fromMomentID].flatMap { peopleByID[$0.primaryPersonID] }
                let color = link.tinted ? (person?.color.line ?? Tokens.Palette.ink).opacity(0.6) : Tokens.Palette.ink.opacity(0.35)
                let isDimmed = momentsByID[link.fromMomentID].map(dimmed) ?? false
                context.stroke(
                    path,
                    with: .color(color.opacity(isDimmed ? 0.25 : 1)),
                    style: StrokeStyle(lineWidth: Tokens.Stroke.link, lineCap: .round, dash: [4, 5])
                )
            }

            for hub in map.hubs {
                let r = hub.radius
                let isDimmed = filter != nil && hub.personID != filter
                context.fill(
                    Path(ellipseIn: CGRect(x: hub.position.x - r, y: hub.position.y - r, width: r * 2, height: r * 2)),
                    with: .color(Tokens.Palette.ink.opacity(isDimmed ? 0.2 : 0.85))
                )
            }
        }
        .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight)
        .allowsHitTesting(false)
    }

    private func dimmed(_ moment: Moment) -> Bool {
        filter.map { !moment.personIDs.contains($0) } ?? false
    }
}

extension CGPoint {
    init(map point: MapPoint) {
        self.init(x: point.x, y: point.y)
    }
}
