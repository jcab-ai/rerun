import RerunCore
import SwiftUI

/// 06 — a moment on a torn sheet over the dimmed world: the evidence board,
/// what happened, who's in it, and the play button.
struct MomentDetailView: View {
    @EnvironmentObject private var model: AppModel
    let moment: Moment
    @State private var appeared = false

    private var person: Person? { model.person(moment.primaryPersonID) }
    private var color: PersonColor { person?.color ?? .coral }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop
            card
                .rotationEffect(.degrees(-1))
                .padding(EdgeInsets(top: 40, leading: 46, bottom: 50, trailing: 44))
                .scaleEffect(appeared ? 1 : 0.94, anchor: .top)
                .offset(y: appeared ? 0 : 24)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear { withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { appeared = true } }
    }

    /// The world, out of focus behind the card.
    private var backdrop: some View {
        ZStack(alignment: .topLeading) {
            Tokens.Palette.night
            ZStack(alignment: .topLeading) {
                blob(Tokens.Palette.coral, 160, 70, -5).offset(x: 60, y: 90)
                blob(Tokens.Palette.sun, 160, 70, 6).offset(x: 700, y: 60)
                blob(Tokens.Palette.blue, 150, 70, 5).offset(x: 800, y: 400)
                blob(Tokens.Palette.leaf, 150, 70, -6).offset(x: 300, y: 620)
                Circle()
                    .fill(Tokens.Palette.ink)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 7))
                    .frame(width: 144, height: 144)
                    .offset(x: 420, y: 300)
            }
            .blur(radius: 3)
            .opacity(0.45)
        }
        .contentShape(Rectangle())
        .onTapGesture { close() }
    }

    private func blob(_ fill: Color, _ width: CGFloat, _ height: CGFloat, _ tilt: Double) -> some View {
        RoundedRectangle(cornerRadius: 12).fill(fill).frame(width: width, height: height).rotationEffect(.degrees(tilt))
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 44) {
            EvidenceBoard(moment: moment, person: person, player: model.settings.player)
                .frame(width: 400)
            details
        }
        .padding(.vertical, 44)
        .padding(.horizontal, 48)
        .frame(maxWidth: 890, maxHeight: 660, alignment: .topLeading)
        .background(TornPaperShape(depth: 0.015).fill(Tokens.Palette.card))
        .shadow(Tokens.Shadow(Color.black.opacity(0.4), blur: 36, y: 20))
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
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .overlay(alignment: .topTrailing) { closeButton.offset(x: 14, y: -14) }

            Text(moment.title)
                .textStyle(Tokens.Typography.displayTitle)
                .foregroundStyle(Tokens.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .overlay(alignment: .topTrailing) {
                    if moment.titleIsProvisional {
                        Text("working title")
                            .font(Tokens.Typeface.caveat(bold: false).font(size: 18))
                            .foregroundStyle(Tokens.Palette.coral)
                            .rotationEffect(.degrees(6))
                            .offset(x: 10, y: -14)
                    }
                }

            if !moment.summary.isEmpty {
                Text(moment.summary)
                    .textStyle(Tokens.Typography.body)
                    .foregroundStyle(Tokens.Palette.inkSoft)
                    .lineLimit(7)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let quote = moment.quote {
                Text("“\(quote)” — and \(moment.messageCount - 1) more texts. Play it to find out the rest.")
                    .textStyle(Tokens.Typography.body)
                    .foregroundStyle(Tokens.Palette.inkSoft)
            }

            starring

            VStack(alignment: .leading, spacing: 12) {
                if let outcome = moment.lastOutcome {
                    Text("last run: \(outcome)")
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                        .foregroundStyle(Tokens.Palette.pencil)
                        .rotationEffect(.degrees(-2))
                }
                HStack(spacing: 6) {
                    statTag("\(moment.messageCount) real texts")
                    if let duration = moment.durationLabel { statTag(duration) }
                    statTag(moment.lengthLabel)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Button { model.play(moment) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill").font(.system(size: 18, weight: .black))
                        Text(moment.hasBeenPlayed ? "play again" : "play")
                    }
                }
                .buttonStyle(HardShadowButtonStyle(text: Tokens.Typography.buttonPlay))
                .keyboardShortcut(.defaultAction)
                .help(model.canPlay(moment) ? "Play \(moment.title)" : "Pick a story model in Settings first")

                Button("+ add context") {
                    model.openNotes(personID: moment.primaryPersonID, momentID: moment.id)
                }
                .buttonStyle(UnderlineLinkButtonStyle())

                if moment.playCount > 0 {
                    Text("played \(moment.playCount)×")
                        .font(Tokens.Typeface.caveat(bold: true).font(size: 17))
                        .foregroundStyle(Tokens.Palette.ink)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 9)
                        .background(Capsule().fill(Tokens.Palette.sun))
                        .rotationEffect(.degrees(8))
                }
            }
        }
    }

    private var closeButton: some View {
        Button(action: close) {
            Text("✕")
                .font(Tokens.Typeface.fredoka(.regular).font(size: 18))
                .foregroundStyle(Tokens.Palette.ink)
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.chip))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
        .help("Back to the map (esc)")
    }

    private var starring: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            Text("STARRING")
                .textStyle(Tokens.Typography.monoEyebrow)
                .foregroundStyle(Tokens.Palette.pencil)
            HStack(spacing: Tokens.Space.ml) {
                ForEach(Array(moment.personIDs.compactMap(model.person).enumerated()), id: \.element.id) { index, person in
                    Button { model.openStoryline(person.id) } label: {
                        PersonPill(
                            initial: person.isGroup ? "🦆" : person.initial,
                            name: person.displayName,
                            caption: model.voice(person.id)?.summary,
                            color: person.color.fill
                        )
                    }
                    .buttonStyle(LiftOnHoverStyle())
                    .rotationEffect(.degrees(Tokens.Tilt.chipStarring[index % 2]))
                }
                PersonPill(initial: "you", name: model.settings.player.name, caption: nil, color: Tokens.Palette.ink)
                    .rotationEffect(.degrees(Tokens.Tilt.chipStarring[1]))
            }
        }
    }

    private func statTag(_ text: String) -> some View {
        Text(text)
            .textStyle(Tokens.Typography.monoCaption.resized(10.5))
            .foregroundStyle(Tokens.Palette.ink)
            .lineLimit(1)
            .fixedSize()
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .dashedBox(color: Tokens.Palette.ink, radius: Tokens.Radius.chipSquare)
    }

    private func close() {
        model.openMomentID = nil
    }
}

/// White pill with an avatar and a handwritten voice caption ("lowercase, panics in bursts").
struct PersonPill: View {
    var initial: String
    var name: String
    var caption: String?
    var color: Color

    var body: some View {
        HStack(spacing: Tokens.Space.m) {
            Text(initial)
                .font(Tokens.Typeface.fredoka(.bold).font(size: initial.count > 1 && initial != "🦆" ? 12 : 16))
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
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 16))
                        .foregroundStyle(Tokens.Palette.pencil)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .background(Capsule().fill(Color.white))
        .shadow(Tokens.Shadows.pill)
    }
}
