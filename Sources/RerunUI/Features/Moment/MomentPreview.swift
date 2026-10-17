import RerunCore
import SwiftUI

/// What opens when you tap a sticker. The full moment detail screen (evidence
/// prop, add-context, play) is the next iteration; this shows the card's
/// layout and real data so the map is navigable now.
struct MomentPreview: View {
    @EnvironmentObject private var model: AppModel
    let moment: Moment

    private var person: Person? { model.person(moment.primaryPersonID) }
    private var color: PersonColor { person?.color ?? .coral }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Tokens.Palette.night.opacity(0.94)
                .contentShape(Rectangle())
                .onTapGesture { close() }

            HStack(alignment: .top, spacing: 44) {
                evidenceBoard
                    .frame(width: 400)
                details
            }
            .padding(.vertical, 44)
            .padding(.horizontal, 48)
            .frame(maxWidth: 890, maxHeight: 660, alignment: .topLeading)
            .background(TornPaperShape(depth: 0.015).fill(Tokens.Palette.card))
            .shadow(Tokens.Shadow(Color.black.opacity(0.4), blur: 36, y: 20))
            .rotationEffect(.degrees(-1))
            .padding(.top, 40)
            .padding(.leading, 46)
            .padding(.trailing, 44)
            .padding(.bottom, 50)
        }
    }

    private var evidenceBoard: some View {
        ZStack(alignment: .bottomLeading) {
            KraftPaper(period: 6, fibre: Color(.sRGB, red: 120 / 255, green: 90 / 255, blue: 50 / 255, opacity: 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            if let evidence = moment.evidence {
                Text(evidence.displayLabel)
                    .textStyle(Tokens.Typography.handLarge)
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text("EVIDENCE · \(moment.evidence == nil ? "NONE YET" : "1 ITEM")\nthe prop arrives with the moment screen")
                .textStyle(Tokens.Typography.monoCaption.withLineHeight(1.6))
                .foregroundStyle(Tokens.Palette.pencilDark)
                .padding(.leading, 24)
                .padding(.bottom, 22)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: Tokens.Space.sm) {
                Text(DateFormatter.rerun("EEE, MMM d, yyyy").string(from: moment.date).uppercased())
                    .textStyle(Tokens.Typography.monoSmall)
                    .foregroundStyle(color.onFill)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: Tokens.Radius.chipSquare).fill(color.fill))
                if let location = moment.location {
                    Text(location.uppercased())
                        .textStyle(Tokens.Typography.monoSmall)
                        .foregroundStyle(Tokens.Palette.pencil)
                }
                Spacer()
                Button(action: close) {
                    Text("✕")
                        .textStyle(Tokens.Typography.navItem.resized(18))
                        .foregroundStyle(Tokens.Palette.ink)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.chip))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .offset(x: 14, y: -14)
            }

            Text(moment.title)
                .textStyle(Tokens.Typography.displayTitle)
                .foregroundStyle(Tokens.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            if !moment.summary.isEmpty {
                Text(moment.summary)
                    .textStyle(Tokens.Typography.body)
                    .foregroundStyle(Tokens.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            starring

            HStack(spacing: Tokens.Space.s) {
                statTag("\(moment.messageCount) real texts")
                if moment.playCount > 0 { statTag("played \(moment.playCount)×") }
            }

            Spacer(minLength: 0)

            HStack(spacing: Tokens.Space.lx) {
                Button {} label: {
                    HStack(spacing: Tokens.Space.ml) {
                        Text("▶").font(Tokens.Typeface.fredoka(.bold).font(size: 18))
                        Text("play")
                    }
                }
                .buttonStyle(HardShadowButtonStyle(text: Tokens.Typography.buttonPlay))
                .disabled(true)
                .help("The play screen is the next iteration")
                Text("play & add context arrive with the next screens")
                    .textStyle(Tokens.Typography.handSmall)
                    .foregroundStyle(Tokens.Palette.pencil)
            }
        }
    }

    private var starring: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("STARRING")
                .textStyle(Tokens.Typography.monoEyebrow)
                .foregroundStyle(Tokens.Palette.pencil)
            HStack(spacing: Tokens.Space.ml) {
                ForEach(Array(moment.personIDs.compactMap(model.person).enumerated()), id: \.element.id) { index, person in
                    personPill(
                        initial: person.initial,
                        name: person.displayName,
                        caption: model.voices[person.id]?.summary,
                        color: person.color.fill,
                        tilt: Tokens.Tilt.chipStarring[index % 2]
                    )
                }
                personPill(initial: "you", name: model.settings.player.name, caption: nil, color: Tokens.Palette.ink, tilt: Tokens.Tilt.chipStarring[1])
            }
        }
    }

    private func personPill(initial: String, name: String, caption: String?, color: Color, tilt: Double) -> some View {
        HStack(spacing: Tokens.Space.m) {
            Text(initial)
                .font(Tokens.Typeface.fredoka(.bold).font(size: initial.count > 1 ? 12 : 16))
                .foregroundStyle(Color.white)
                .frame(width: Tokens.Metrics.avatar, height: Tokens.Metrics.avatar)
                .background(Circle().fill(color))
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                .background(Circle().fill(color).padding(-1.5))
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .textStyle(Tokens.Typography.navItemActive)
                    .foregroundStyle(Tokens.Palette.ink)
                if let caption, !caption.isEmpty {
                    Text(caption)
                        .textStyle(Tokens.Typography.handSmall.resized(16))
                        .foregroundStyle(Tokens.Palette.pencil)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .background(Capsule().fill(Color.white))
        .shadow(Tokens.Shadows.pill)
        .rotationEffect(.degrees(tilt))
    }

    private func statTag(_ text: String) -> some View {
        Text(text)
            .textStyle(Tokens.Typography.monoCaption.resized(10.5))
            .foregroundStyle(Tokens.Palette.ink)
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .dashedBox(color: Tokens.Palette.ink, radius: Tokens.Radius.chipSquare)
    }

    private func close() {
        model.openMomentID = nil
    }
}
