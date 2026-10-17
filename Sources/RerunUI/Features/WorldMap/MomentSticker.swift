import RerunCore
import SwiftUI

/// A moment on the world map: date + person, title, and the evidence it comes with.
struct MomentSticker: View {
    let moment: Moment
    let person: Person?
    let node: MapNode
    let isFeatured: Bool
    let action: () -> Void
    @State private var hovering = false

    private var color: PersonColor { person?.color ?? .coral }
    private var isPaper: Bool { node.variant == .paper }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                Text(meta)
                    .textStyle(Tokens.Typography.monoMicro.withTracking(isFeatured ? 0.5 : 0))
                Text(moment.title)
                    .textStyle(isFeatured ? Tokens.Typography.nodeTitleFeatured : Tokens.Typography.nodeTitle)
                    .fixedSize(horizontal: false, vertical: true)
                if let evidence = moment.evidence {
                    Text("+ \(evidence.displayLabel)")
                        .textStyle(Tokens.Typography.monoMicro)
                        .opacity(isFeatured ? 0.9 : 1)
                }
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(isPaper ? Tokens.Palette.ink : color.onFill)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, isFeatured ? 11 : 10)
            .padding(.horizontal, isFeatured ? 13 : 12)
            .sticker(isPaper ? Tokens.Palette.card : color.fill, border: isPaper ? color.fill : .white)
            .frame(width: node.width)
            .background {
                if isFeatured {
                    // The 4pt ink ring around the featured sticker's white border.
                    RoundedRectangle(cornerRadius: Tokens.Radius.sticker + Tokens.Stroke.sticker)
                        .fill(Tokens.Palette.ink)
                        .padding(-Tokens.Stroke.sticker)
                }
            }
            .shadow(isFeatured ? Tokens.Shadows.stickerFeatured : Tokens.Shadows.sticker)
            .overlay(alignment: .topTrailing) {
                if isFeatured && moment.playCount > 0 {
                    PlayedBadge(count: moment.playCount)
                        .offset(x: 14, y: -12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .rotationEffect(.degrees(node.tilt))
        .scaleEffect(hovering ? 1.04 : 1)
        .offset(y: hovering ? -3 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
        .onHover { hovering = $0 }
        .help(moment.title)
        .accessibilityLabel("\(moment.title), \(meta.lowercased())")
    }

    /// "JUN 14 '24 · MAYA" for the featured sticker, "AUG '19 · MAYA" otherwise.
    private var meta: String {
        let date = DateFormatter.rerun(isFeatured ? "MMM d ''yy" : "MMM ''yy").string(from: moment.date)
        return "\(date) · \(person?.displayName ?? "")".uppercased()
    }
}

/// "played 3×" in handwriting on a yellow tag.
private struct PlayedBadge: View {
    let count: Int

    var body: some View {
        Text("played \(count)×")
            .textStyle(Tokens.Typography.handBadge)
            .foregroundStyle(Tokens.Palette.ink)
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .padding(Tokens.Stroke.chip)
            .background(Capsule().fill(Tokens.Palette.sun))
            .overlay(Capsule().strokeBorder(Color.white, lineWidth: Tokens.Stroke.chip))
            .fixedSize()
            .rotationEffect(.degrees(Tokens.Tilt.playedBadge))
    }
}

/// The player at the center of the world.
struct YouNode: View {
    let player: PlayerProfile

    var body: some View {
        VStack(spacing: Tokens.Space.s) {
            VStack(spacing: Tokens.Space.xs) {
                Text("you")
                    .textStyle(Tokens.Typography.youLabel)
                Text(tagline)
                    .textStyle(Tokens.Typography.monoCaption)
                    .foregroundStyle(Tokens.Palette.sun)
            }
            .foregroundStyle(Color.white)
            .frame(width: Tokens.Metrics.youDiameter + Tokens.Stroke.you * 2, height: Tokens.Metrics.youDiameter + Tokens.Stroke.you * 2)
            .background(Circle().fill(Tokens.Palette.ink))
            .overlay(Circle().strokeBorder(Color.white, lineWidth: Tokens.Stroke.you))
            .background(Circle().fill(Tokens.Palette.ink).padding(-3))
            .shadow(Tokens.Shadows.you)

            Text("tap any moment to open it")
                .textStyle(Tokens.Typography.handCaption)
                .foregroundStyle(Tokens.Palette.ink)
                .padding(.horizontal, Tokens.Space.sm)
                .background(Tokens.Palette.card)
                .rotationEffect(.degrees(Tokens.Tilt.youCaption))
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }

    /// "JULES · 29"
    private var tagline: String {
        [player.name.uppercased(), player.age.map(String.init)].compactMap { $0 }.joined(separator: " · ")
    }
}

/// Bottom-right key: solid line = played, dotted = not played yet.
struct MapLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            row(dashed: false, "played")
            row(dashed: true, "not played yet")
        }
        .textStyle(Tokens.Typography.monoCaption)
        .foregroundStyle(Tokens.Palette.ink)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: Tokens.Radius.control).fill(Color.white))
        .shadow(Tokens.Shadows.floating)
        .rotationEffect(.degrees(Tokens.Tilt.legend))
        .fixedSize()
    }

    private func row(dashed: Bool, _ label: String) -> some View {
        HStack(spacing: Tokens.Space.s) {
            Path { path in
                path.move(to: CGPoint(x: dashed ? 1.25 : 0, y: 1.25))
                path.addLine(to: CGPoint(x: 22, y: 1.25))
            }
            .stroke(Tokens.Palette.ink, style: StrokeStyle(lineWidth: Tokens.Stroke.edge, lineCap: dashed ? .round : .butt, dash: dashed ? [0.01, 5] : []))
            .frame(width: 22, height: 2.5)
            Text(label)
        }
    }
}
