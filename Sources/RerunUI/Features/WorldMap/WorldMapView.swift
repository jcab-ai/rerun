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
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot
    /// 0 → 1 as the lines draw themselves out from "you".
    @State private var drawn: CGFloat = 0
    @State private var shown = false

    var body: some View {
        let featuredID = model.featuredMomentID
        let settled = isRenderingSnapshot || shown
        ZStack(alignment: .topLeading) {
            DeskDoodles(featured: featuredID.flatMap(model.map.node(for:)), years: model.map.yearsSpanned())

            OrbitRing()
                .position(x: WorldMap.center.x, y: WorldMap.center.y - 16)

            MapLines(map: model.map, moments: model.moments, people: model.people, filter: model.personFilter, progress: isRenderingSnapshot ? 1 : drawn)

            ForEach(Array(model.map.hubs.enumerated()), id: \.offset) { index, hub in
                if let count = hub.hiddenCount, let person = hub.personID.flatMap(model.person) {
                    Button { model.openStoryline(person.id) } label: {
                        CountTag("+\(count)", fill: person.color.fill, foreground: person.color.onFill)
                    }
                    .buttonStyle(LiftOnHoverStyle())
                    .help("\(count) more moments with \(person.displayName)")
                    .frame(width: 0, height: 0, alignment: .leading)
                    .position(x: hub.position.x + 10, y: hub.position.y)
                    .opacity(dimmed(personID: person.id) ? 0.25 : (settled ? 1 : 0))
                    .animation(.easeOut(duration: 0.3).delay(0.6 + Double(index) * 0.05), value: shown)
                }
            }

            ForEach(Array(model.map.nodes.enumerated()), id: \.element.momentID) { index, node in
                if let moment = model.moment(node.momentID) {
                    MomentSticker(
                        moment: moment,
                        person: model.person(moment.primaryPersonID),
                        node: node,
                        isFeatured: moment.id == featuredID
                    ) {
                        model.openMomentID = moment.id
                    }
                    .scaleEffect(settled ? 1 : 0.55)
                    .opacity(settled ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.62).delay(0.15 + Double(index) * 0.045), value: shown)
                    .position(x: node.position.x, y: node.position.y)
                    .opacity(model.isDimmed(moment) ? 0.25 : 1)
                    .zIndex(moment.id == featuredID ? 2 : 1)
                }
            }

            YouNode(player: model.player)
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
        .onAppear {
            guard !isRenderingSnapshot else { return }
            withAnimation(.easeInOut(duration: 1.1)) { drawn = 1 }
            shown = true
        }
    }

    private func dimmed(personID: String) -> Bool {
        model.personFilter.map { $0 != personID } ?? false
    }
}

/// Curved lines from "you" to each sticker (solid once played, dotted before),
/// thin dashed links between related moments, and the hub dots. They draw
/// themselves out from the center as `progress` goes 0 → 1.
private struct MapLines: View {
    let map: WorldMap
    let moments: [Moment]
    let people: [Person]
    let filter: String?
    var progress: CGFloat

    var body: some View {
        let momentsByID = Dictionary(moments.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let peopleByID = Dictionary(people.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        ZStack(alignment: .topLeading) {
            ForEach(map.nodes, id: \.momentID) { node in
                if let moment = momentsByID[node.momentID] {
                    let color = peopleByID[moment.primaryPersonID]?.color.line ?? Tokens.Palette.ink
                    CurveShape(from: WorldMap.center, control: node.control, to: node.position)
                        .trim(from: 0, to: progress)
                        .stroke(
                            color.opacity(dimmed(moment) ? 0.25 : 1),
                            style: StrokeStyle(lineWidth: Tokens.Stroke.edge, lineCap: .round, dash: moment.hasBeenPlayed ? [] : [2, 7])
                        )
                }
            }
            ForEach(Array(map.links.enumerated()), id: \.offset) { _, link in
                if let from = map.node(for: link.fromMomentID), let to = map.node(for: link.toMomentID) {
                    let person = momentsByID[link.fromMomentID].flatMap { peopleByID[$0.primaryPersonID] }
                    let color = link.tinted ? (person?.color.line ?? Tokens.Palette.ink).opacity(0.6) : Tokens.Palette.ink.opacity(0.35)
                    let isDimmed = momentsByID[link.fromMomentID].map(dimmed) ?? false
                    CurveShape(from: from.position, control: link.control, to: to.position)
                        .trim(from: 0, to: max(0, progress * 2 - 1))
                        .stroke(color.opacity(isDimmed ? 0.25 : 1), style: StrokeStyle(lineWidth: Tokens.Stroke.link, lineCap: .round, dash: [4, 5]))
                }
            }
            ForEach(Array(map.hubs.enumerated()), id: \.offset) { _, hub in
                let isDimmed = filter != nil && hub.personID != filter
                Circle()
                    .fill(Tokens.Palette.ink.opacity(isDimmed ? 0.2 : 0.85))
                    .frame(width: hub.radius * 2, height: hub.radius * 2)
                    .scaleEffect(progress)
                    .position(x: hub.position.x, y: hub.position.y)
            }
        }
        .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func dimmed(_ moment: Moment) -> Bool {
        filter.map { !moment.personIDs.contains($0) } ?? false
    }
}

/// A quadratic curve in map coordinates.
struct CurveShape: Shape {
    var from: MapPoint
    var control: MapPoint
    var to: MapPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(map: from))
        path.addQuadCurve(to: CGPoint(map: to), control: CGPoint(map: control))
        return path
    }
}

/// A dashed orbit around "you", turning slowly, with a little moon on it.
private struct OrbitRing: View {
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot
    @State private var turning = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Tokens.Palette.ink.opacity(0.16), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [1, 7]))
            Circle()
                .fill(Tokens.Palette.sun)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .frame(width: 12, height: 12)
                .offset(y: -118)
        }
        .frame(width: 236, height: 236)
        .rotationEffect(.degrees(turning ? 360 : 38))
        .allowsHitTesting(false)
        .onAppear {
            guard !isRenderingSnapshot else { return }
            withAnimation(.linear(duration: 90).repeatForever(autoreverses: false)) { turning = true }
        }
    }
}

/// Things left lying on the desk: a coffee ring, a postmark, sparkles, and a
/// note pointing at the moment you played last.
private struct DeskDoodles: View {
    let featured: MapNode?
    let years: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            CoffeeRing().frame(width: 110, height: 110).position(x: 64, y: 612)
            Postmark(top: "RERUN", middle: "\(years) YRS", bottom: "LOCAL ONLY", color: Tokens.Palette.coral)
                .rotationEffect(.degrees(-12))
                .position(x: 934, y: 46)
            sparkle(Tokens.Palette.sun, 18, at: CGPoint(x: 452, y: 202), tilt: 12)
            sparkle(Tokens.Palette.blue, 14, at: CGPoint(x: 612, y: 462), tilt: -8)
            sparkle(Tokens.Palette.grape, 16, at: CGPoint(x: 212, y: 398), tilt: 20)
            sparkle(Tokens.Palette.coral, 12, at: CGPoint(x: 940, y: 352), tilt: 0)
            if let featured, featured.position.x - featured.width / 2 > 110 {
                let target = CGPoint(x: featured.position.x - featured.width / 2 - 6, y: featured.position.y - 6)
                Text("start here")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 21))
                    .foregroundStyle(Tokens.Palette.ink)
                    .rotationEffect(.degrees(-8))
                    .position(x: target.x - 70, y: target.y - 46)
                Doodle.arrow
                    .foregroundStyle(Tokens.Palette.ink.opacity(0.75))
                    .frame(width: 46, height: 30)
                    .rotationEffect(.degrees(28))
                    .position(x: target.x - 26, y: target.y - 18)
            }
        }
        .frame(width: WorldMap.canvasWidth, height: WorldMap.canvasHeight, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func sparkle(_ color: Color, _ size: CGFloat, at point: CGPoint, tilt: Double) -> some View {
        Doodle.star
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(tilt))
            .position(point)
    }
}

extension CGPoint {
    init(map point: MapPoint) {
        self.init(x: point.x, y: point.y)
    }
}
