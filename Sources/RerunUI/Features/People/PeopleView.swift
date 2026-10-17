import RerunCore
import SwiftUI

/// 02 People — everyone in the world as photo-booth strips; tap one for their storyline.
struct PeopleView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let id = model.storylinePersonID, let person = model.person(id) {
            StorylineView(person: person)
                .id(person.id)
                .transition(.opacity)
        } else {
            grid
        }
    }

    private static let tilts: [Double] = [-4, 3, -2, 5, -5, 2, -3, 4]
    private static let drops: [CGFloat] = [0, 22, 6, 30, 12, 40, 14, 4]

    private var grid: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            AdaptiveScroll {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    strips(model.includedPeople, included: true)
                    let excluded = model.people.filter { !$0.included }
                    if !excluded.isEmpty {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 12) {
                                Text("LEFT OUT").textStyle(Tokens.Typography.monoEyebrow).foregroundStyle(Tokens.Palette.pencil)
                                Text("not read, never sent anywhere. add them back in Settings.")
                                    .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                                    .foregroundStyle(Tokens.Palette.pencil)
                            }
                            strips(Array(excluded.prefix(Self.leftOutShown)), included: false)
                            if excluded.count > Self.leftOutShown {
                                Text("+ \(excluded.count - Self.leftOutShown) more conversations — bring anyone back from Settings")
                                    .font(Tokens.Typeface.caveat(bold: false).font(size: 20))
                                    .foregroundStyle(Tokens.Palette.pencil)
                                    .rotationEffect(.degrees(-1.5))
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: 30, leading: 44, bottom: 40, trailing: 40))
            }
        }
    }

    /// Left-out strips shown before the rest collapse into a count.
    private static let leftOutShown = 6

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("Your people")
                .textStyle(Tokens.Typography.screenTitle)
                .foregroundStyle(Tokens.Palette.ink)
            Text("\(model.includedPeople.count) storylines, \(model.includedPeople.reduce(0) { $0 + $1.momentCount }.formatted()) moments")
                .textStyle(Tokens.Typography.handNote)
                .foregroundStyle(Tokens.Palette.pencil)
                .rotationEffect(.degrees(Tokens.Tilt.headerNote))
            Spacer()
            Text("tap a strip for their storyline ↓")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 20))
                .foregroundStyle(Tokens.Palette.ink)
                .rotationEffect(.degrees(3))
        }
    }

    private func strips(_ people: [Person], included: Bool) -> some View {
        HStack(alignment: .top, spacing: 30) {
            ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                Button { model.openStoryline(person.id) } label: {
                    VStack(spacing: 10) {
                        PolaroidStrip(person: person, tileSize: CGSize(width: 104, height: 74), caption: person.isGroup ? "\(person.displayName) 🦆" : person.displayName, showsTape: included)
                            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 22, y: 10))
                        Text(person.momentCount > 0 ? "\(person.momentCount) moments" : "\(person.messageCount.formatted()) texts")
                            .textStyle(Tokens.Typography.monoSmall)
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Tokens.Palette.ink))
                        if let summary = model.voice(person.id)?.summary, !summary.isEmpty {
                            Text(summary)
                                .font(Tokens.Typeface.caveat(bold: false).font(size: 17))
                                .foregroundStyle(Tokens.Palette.pencil)
                                .multilineTextAlignment(.center)
                                .frame(width: 130)
                        }
                    }
                    .saturation(included ? 1 : 0.3)
                    .opacity(included ? 1 : 0.6)
                    .rotationEffect(.degrees(Self.tilts[index % Self.tilts.count]))
                    .padding(.top, Self.drops[index % Self.drops.count])
                    .contentShape(Rectangle())
                }
                .buttonStyle(LiftOnHoverStyle())
            }
        }
    }
}

/// 08 — one person's storyline: who they are, how they text, and their
/// moments strung along a hand-drawn line through the years.
struct StorylineView: View {
    @EnvironmentObject private var model: AppModel
    let person: Person

    private var moments: [Moment] { model.moments(with: person.id) }
    private var voice: VoiceProfile? { model.voice(person.id) }
    private var isLongest: Bool {
        // Group chats are loud, not long — the title goes to a person.
        model.includedPeople.filter { !$0.isGroup }.max { $0.messageCount < $1.messageCount }?.id == person.id
    }

    private static let slot: CGFloat = 190
    private static let badgeColors: [PersonColor] = [.coral, .sun, .blue, .grape, .leaf]
    private static let badgeTilts: [Double] = [-2, 2, -1, 1.5, -2, 1]

    var body: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            header
                .padding(EdgeInsets(top: 30, leading: 44, bottom: 0, trailing: 40))
            timeline
                .padding(.top, 250)
            Button("← everyone") { model.storylinePersonID = nil }
                .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.caveat(bold: false), 20), color: Tokens.Palette.pencil))
                .rotationEffect(.degrees(-3))
                .place(left: 40, bottom: 26)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 30) {
            PolaroidStrip(
                person: person,
                tileSize: CGSize(width: 92, height: 66),
                caption: person.since.map { "’" + DateFormatter.rerun("yy").string(from: $0) } ?? "",
                captionSize: 19
            )
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 22, y: 10))
            .rotationEffect(.degrees(-5))

            VStack(alignment: .leading, spacing: 10) {
                Text((person.relationship ?? (person.isGroup ? "group chat" : "texting since \(person.since.map { DateFormatter.rerun("yyyy").string(from: $0) } ?? "forever")")).uppercased())
                    .textStyle(Tokens.Typography.monoSmall.withTracking(1))
                    .foregroundStyle(Tokens.Palette.pencil)
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(person.nameForTitles)
                        .font(Tokens.Typeface.fredoka(.bold).font(size: 54))
                        .tracking(-1.5)
                        .foregroundStyle(Tokens.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if isLongest {
                        Text("your longest storyline")
                            .font(Tokens.Typeface.caveat(bold: false).font(size: 24))
                            .foregroundStyle(person.color.line)
                            .rotationEffect(.degrees(-3))
                    }
                }
                Text("\(person.messageCount.formatted()) messages · \(person.momentCount) moments · \(moments.filter(\.hasBeenPlayed).reduce(0) { $0 + $1.playCount }) played")
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 13))
                    .foregroundStyle(Tokens.Palette.ink)
                FlowLayout(spacing: 8) {
                    ForEach(Array((voice?.badges ?? []).enumerated()), id: \.offset) { index, badge in
                        let color = Self.badgeColors[index % Self.badgeColors.count]
                        Text(badge)
                            .font(Tokens.Typeface.fredoka(.semibold).font(size: 14))
                            .foregroundStyle(color.onFill)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .sticker(color.fill, borderWidth: 3, radius: 10)
                            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.18), blur: 8, y: 3))
                            .rotationEffect(.degrees(Self.badgeTilts[index % Self.badgeTilts.count]))
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                Button {
                    if let latest = moments.last { model.play(latest) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill").font(.system(size: 14, weight: .black))
                        Text("play latest")
                    }
                    .frame(width: 104)
                }
                .buttonStyle(HardShadowButtonStyle(text: Tokens.TextStyle(.fredoka(.semibold), 16), padding: EdgeInsets(top: 12, leading: 22, bottom: 12, trailing: 22), shadowOffset: Tokens.Shadows.hardOffsetSmall))
                .disabled(moments.isEmpty)
                Button("+ context") { model.openNotes(personID: person.id) }
                    .buttonStyle(PillButtonStyle(fill: .white, foreground: Tokens.Palette.ink, border: Tokens.Palette.ink, text: Tokens.TextStyle(.fredoka(.semibold), 15), padding: EdgeInsets(top: 8, leading: 32, bottom: 8, trailing: 32)))
            }
        }
    }

    // MARK: Timeline

    private var timeline: some View {
        let width = max(980, CGFloat(moments.count) * Self.slot + 80)
        return AdaptiveScroll(axes: .horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Wave(points: wavePoints(width: width))
                    .stroke(person.color.line, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: width, height: 500)
                ForEach(yearMarks(width: width), id: \.year) { mark in
                    Circle()
                        .fill(Tokens.Palette.ink)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                        .frame(width: 20, height: 20)
                        .position(mark.point)
                    Text(String(mark.year))
                        .textStyle(Tokens.TextStyle(.mono(bold: true), 12))
                        .foregroundStyle(Tokens.Palette.ink)
                        .position(x: mark.point.x, y: mark.point.y + (mark.below ? 24 : -24))
                }
                ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                    Button { model.openMomentID = moment.id } label: {
                        StorylineCard(moment: moment, person: person, style: style(for: moment, index: index))
                    }
                    .buttonStyle(LiftOnHoverStyle())
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? (index % 4 == 0 ? -4 : -3) : (index % 4 == 1 ? 4 : 5)))
                    .offset(x: 30 + CGFloat(index) * Self.slot, y: index.isMultiple(of: 2) ? 40 : 296)
                }
            }
            .frame(width: width, height: 500, alignment: .topLeading)
        }
        .frame(height: 500)
        .overlay(alignment: .bottomTrailing) {
            let more = max(0, person.momentCount - moments.count)
            if more > 0 {
                Text("scroll for \(more) more →")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 22))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-3))
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                    .allowsHitTesting(false)
            }
        }
    }

    private func wavePoints(width: CGFloat) -> [CGPoint] {
        stride(from: 0, through: width, by: 160).enumerated().map { index, x in
            CGPoint(x: x + 20, y: 250 + (index.isMultiple(of: 2) ? -1 : 1) * CGFloat(18 + (index % 3) * 8))
        }
    }

    private struct YearMark { var year: Int; var point: CGPoint; var below: Bool }

    private func yearMarks(width: CGFloat) -> [YearMark] {
        let points = wavePoints(width: width)
        var seen = Set<Int>()
        var marks: [YearMark] = []
        for (index, moment) in moments.enumerated() {
            let year = Calendar.current.component(.year, from: moment.date)
            guard seen.insert(year).inserted else { continue }
            let x = 30 + CGFloat(index) * Self.slot + 50
            marks.append(YearMark(year: year, point: CGPoint(x: x, y: waveY(at: x, points)), below: marks.count.isMultiple(of: 2)))
        }
        return marks
    }

    /// Linear interpolation along the wave's points, close enough for placing dots.
    private func waveY(at x: CGFloat, _ points: [CGPoint]) -> CGFloat {
        guard let after = points.firstIndex(where: { $0.x >= x }), after > 0 else { return points.first?.y ?? 250 }
        let a = points[after - 1], b = points[after]
        let t = (x - a.x) / max(1, b.x - a.x)
        // Match the smooth curve's ease between points.
        let eased = t * t * (3 - 2 * t)
        return a.y + (b.y - a.y) * eased
    }

    private func style(for moment: Moment, index: Int) -> StorylineCard.Style {
        if moment.evidence?.kind == .boardingPass { return .boardingPass }
        if moment.evidence?.kind == .receipt && moment.photoCaption == nil { return .receipt }
        if moment.stat != nil { return .outlined }
        if moment.quote != nil && moment.evidence == nil && moment.photoCaption == nil { return .note }
        // Filled stickers take turns through the palette, so a storyline isn't one color.
        return .filled(PersonColor.allCases[(index + 2) % PersonColor.allCases.count])
    }
}

/// A smooth line through points (Catmull-Rom → cubic Béziers).
struct Wave: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])
        for index in 0..<(points.count - 1) {
            let p0 = points[max(index - 1, 0)], p1 = points[index], p2 = points[index + 1], p3 = points[min(index + 2, points.count - 1)]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        return path
    }
}

/// A moment card on a storyline, in one of the mockup's five styles.
struct StorylineCard: View {
    enum Style { case note, filled(PersonColor), outlined, boardingPass, receipt }

    let moment: Moment
    let person: Person
    let style: Style

    private var monthYear: String { DateFormatter.rerun("MMM yyyy").string(from: moment.date).uppercased() }

    var body: some View {
        switch style {
        case .note:
            VStack(alignment: .leading, spacing: 6) {
                Text(monthYear).textStyle(Tokens.Typography.monoMicro).foregroundStyle(Tokens.Palette.pencil)
                Text(moment.title).textStyle(Tokens.TextStyle(.fredoka(.semibold), 17, lineHeight: 1.15)).foregroundStyle(Tokens.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let quote = moment.quote {
                    Text(quote)
                        .font(.system(size: 12))
                        .foregroundStyle(Tokens.Palette.ink)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Tokens.Palette.Messages.bubbleThem))
                        .fixedSize(horizontal: false, vertical: true)
                }
                playedLine
            }
            .padding(14)
            .frame(width: 170, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
            .overlay(alignment: .top) { Tape(width: 60, height: 20, angle: 0).offset(y: -10) }
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 18, y: 8))
        case .filled(let color):
            VStack(alignment: .leading) {
                Text("\(monthYear) · \(moment.messageCount) MSGS").textStyle(Tokens.Typography.monoMicro)
                Spacer(minLength: 8)
                Text(moment.title).textStyle(Tokens.TextStyle(.fredoka(.bold), 21, lineHeight: 1.05)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(moment.hasBeenPlayed ? "played \(moment.playCount)×" : "not played yet")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 17))
            }
            .foregroundStyle(color.onFill)
            .padding(14)
            .frame(width: 180, height: 140, alignment: .leading)
            .sticker(color.fill, borderWidth: Tokens.Stroke.panel, radius: Tokens.Radius.card)
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 18, y: 8))
        case .outlined:
            VStack(alignment: .leading, spacing: 6) {
                Text(monthYear + (moment.tagline.map { " · \($0.uppercased())" } ?? "")).textStyle(Tokens.Typography.monoMicro).foregroundStyle(Tokens.Palette.pencil)
                Text(moment.title).textStyle(Tokens.TextStyle(.fredoka(.semibold), 17, lineHeight: 1.15)).foregroundStyle(Tokens.Palette.ink)
                if let stat = moment.stat {
                    Text(stat).textStyle(Tokens.TextStyle(.mono(bold: false), 10)).foregroundStyle(Tokens.Palette.coral)
                }
            }
            .padding(14)
            .frame(width: 180, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Tokens.Palette.card))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Tokens.Palette.ink, lineWidth: 3))
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 18, y: 8))
        case .boardingPass:
            MiniBoardingPass(evidence: moment.evidence ?? Evidence(.boardingPass), title: moment.title, width: 210)
                .overlay(alignment: .bottomTrailing) {
                    if moment.hasBeenPlayed {
                        Text("played \(moment.playCount)×")
                            .font(Tokens.Typeface.caveat(bold: true).font(size: 16))
                            .foregroundStyle(Tokens.Palette.ink)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 9)
                            .background(Capsule().fill(Tokens.Palette.sun))
                            .overlay(Capsule().strokeBorder(Color.white, lineWidth: 2))
                            .rotationEffect(.degrees(-6))
                            .offset(x: 16, y: 14)
                    }
                }
        case .receipt:
            VStack(spacing: -4) {
                ReceiptPaper(width: 170, fontSize: 10, lineHeight: 1.6) {
                    if let evidence = moment.evidence {
                        Text(evidence[.merchant] ?? "RECEIPT").fontWeight(.bold).frame(maxWidth: .infinity)
                        ForEach(Array(evidence.items.enumerated()), id: \.offset) { _, item in
                            ReceiptLine(item.label, item.amount)
                        }
                        Text(evidence[.date] ?? "").frame(maxWidth: .infinity)
                    }
                }
                Text(moment.title)
                    .textStyle(Tokens.TextStyle(.fredoka(.semibold), 15, lineHeight: 1.1))
                    .foregroundStyle(Tokens.Palette.ink)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(width: 170, alignment: .leading)
                    .background(Tokens.Palette.card)
            }
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 14, y: 8))
        }
    }

    @ViewBuilder
    private var playedLine: some View {
        if moment.hasBeenPlayed, let outcome = moment.lastOutcome {
            Text("last run: \(outcome)")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 15))
                .foregroundStyle(Tokens.Palette.pencil)
        }
    }
}

/// Lays children out left to right, wrapping onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
