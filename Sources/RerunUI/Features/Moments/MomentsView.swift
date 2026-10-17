import RerunCore
import SwiftUI

/// 03 Moments — every moment as a sticker in a scrapbook, year by year.
struct MomentsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tag: MomentTag?
    @State private var unplayedOnly = false

    private var visible: [Moment] {
        model.moments
            .filter { moment in model.person(moment.primaryPersonID)?.included ?? true }
            .filter { tag == nil || $0.tag == tag }
            .filter { !unplayedOnly || !$0.hasBeenPlayed }
            .sorted { $0.date > $1.date }
    }

    private var years: [(year: Int, moments: [Moment])] {
        Dictionary(grouping: visible) { Calendar.current.component(.year, from: $0.date) }
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }

    private var tags: [MomentTag] {
        MomentTag.allCases.filter { tag in model.moments.contains { $0.tag == tag } }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            AdaptiveScroll {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if years.isEmpty {
                        Text("nothing here yet — try another filter.")
                            .font(Tokens.Typeface.caveat(bold: false).font(size: 24))
                            .foregroundStyle(Tokens.Palette.pencil)
                            .padding(.top, 60)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(years, id: \.year) { group in
                        section(group.year, group.moments)
                    }
                }
                .padding(EdgeInsets(top: 22, leading: 34, bottom: 40, trailing: 26))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text("Every moment")
                    .textStyle(Tokens.Typography.screenTitle)
                    .foregroundStyle(Tokens.Palette.ink)
                Text("\(visible.count) stuck in here, newest first")
                    .textStyle(Tokens.Typography.handNote)
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(Tokens.Tilt.headerNote))
                Spacer()
                Toggle(isOn: $unplayedOnly) {
                    Text("not played yet").font(Tokens.Typeface.fredoka(.medium).font(size: 13))
                }
                .toggleStyle(StickerToggleStyle())
            }
            HStack(spacing: 6) {
                FilterChip("everything", isSelected: tag == nil) { tag = nil }
                ForEach(tags, id: \.self) { candidate in
                    FilterChip(candidate.label, color: color(for: candidate), isSelected: tag == candidate) {
                        tag = tag == candidate ? nil : candidate
                    }
                }
            }
        }
    }

    private func section(_ year: Int, _ moments: [Moment]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(year))
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 40))
                    .tracking(-1)
                    .foregroundStyle(Tokens.Palette.ink)
                    .background(alignment: .bottom) {
                        Tape(width: 90, height: 18, angle: -3).offset(y: -6)
                    }
                Text("\(moments.count) moment\(moments.count == 1 ? "" : "s")")
                    .textStyle(Tokens.Typography.monoCaption)
                    .foregroundStyle(Tokens.Palette.pencil)
                DottedLeader(color: Tokens.Palette.pencilLine).frame(height: 2)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 186, maximum: 210), spacing: 22)], alignment: .leading, spacing: 30) {
                ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                    MomentSticker(
                        moment: moment,
                        person: model.person(moment.primaryPersonID),
                        node: MapNode(
                            momentID: moment.id,
                            position: MapPoint(0, 0),
                            control: MapPoint(0, 0),
                            tilt: [-3, 2, -1.5, 3.5, -2.5, 1][index % 6],
                            width: 180,
                            variant: index % 5 == 3 ? .paper : .filled
                        ),
                        isFeatured: false
                    ) {
                        model.openMomentID = moment.id
                    }
                    .overlay(alignment: .topTrailing) {
                        if moment.hasBeenPlayed {
                            Text("✓ \(moment.playCount)×")
                                .font(Tokens.Typeface.caveat(bold: true).font(size: 15))
                                .foregroundStyle(Tokens.Palette.ink)
                                .padding(.horizontal, 7)
                                .background(Capsule().fill(Tokens.Palette.sun))
                                .overlay(Capsule().strokeBorder(Color.white, lineWidth: 2))
                                .rotationEffect(.degrees(10))
                                .offset(x: 4, y: -8)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
    }

    private func color(for tag: MomentTag) -> Color {
        switch tag {
        case .trip, .milestone: Tokens.Palette.blue
        case .romance, .fight: Tokens.Palette.coral
        case .celebration, .chaos: Tokens.Palette.sun
        case .food, .family: Tokens.Palette.leaf
        case .everyday: Tokens.Palette.grape
        }
    }
}

/// The mockup's chunky toggle: a leaf pill with an ink outline and a white knob.
struct StickerToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 8) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().fill(configuration.isOn ? Tokens.Palette.leaf : Tokens.Palette.perforation)
                    Circle().fill(Color.white).frame(width: 16, height: 16).padding(4)
                }
                .frame(width: 40, height: 24)
                .overlay(Capsule().strokeBorder(Tokens.Palette.ink, lineWidth: 2))
                configuration.label.foregroundStyle(Tokens.Palette.ink)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
