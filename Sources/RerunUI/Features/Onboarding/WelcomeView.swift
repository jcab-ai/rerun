import RerunCore
import SwiftUI

/// 01 — the title card, surrounded by the kind of evidence rerun finds.
struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            DotGrid()
            scattered
            card
        }
        .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) { appeared = true } }
    }

    // MARK: The scattered props

    private var scattered: some View {
        ZStack {
            boardingPass
                .rotationEffect(.degrees(-9))
                .place(left: 60, top: 60)
            Tape(width: 80, height: 24, angle: -20).place(left: 84, top: 44)

            ReceiptPaper(width: 150) {
                Text("SUSHI NAKAZAWA").fontWeight(.bold).frame(maxWidth: .infinity)
                ReceiptLine("omakase x2", "190.00")
                ReceiptLine("sake", "24.00")
                DashedRule().padding(.top, 4)
                ReceiptLine("TOTAL", "214.00", bold: true).padding(.top, 4)
                Text("01/19/24 · 9:41 PM").frame(maxWidth: .infinity)
            }
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 20, y: 8))
            .rotationEffect(.degrees(6))
            .place(left: 48, top: 250)

            ticket
                .rotationEffect(.degrees(-5))
                .place(left: 250, top: 470)

            BubbleSticker("u up? lmaooo", tilt: -4).place(left: 70, top: 610)

            photoStrip
                .rotationEffect(.degrees(7))
                .place(right: 70, top: 56)
            Tape(Tokens.Palette.tapeBlue, width: 70, height: 22, angle: 10).place(right: 92, top: 44)

            BubbleSticker("we are NOT missing this flight", fromMe: true, tilt: 5).place(right: 36, top: 362)

            PanelSticker(Tokens.Palette.grape, width: 220, padding: 16, radius: 16) {
                Text("AUG 2019 · 61 MSGS").textStyle(Tokens.Typography.monoCaption.withTracking(1))
                Spacer(minLength: 0)
                Text("Big Sur, zero bars").textStyle(Tokens.TextStyle(.fredoka(.bold), 26, lineHeight: 1.05))
            }
            .foregroundStyle(Color.white)
            .frame(height: 150)
            .rotationEffect(.degrees(-6))
            .place(right: 60, top: 430)

            BubbleSticker("Ok. Call me when you land. - Dad", tilt: 3).place(right: 120, top: 620)

            Text("9 yrs")
                .font(Tokens.Typeface.caveat(bold: true).font(size: 22))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Tokens.Palette.leaf))
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
                .frame(width: 64, height: 64)
                .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 14, y: 6))
                .rotationEffect(.degrees(-12))
                .place(right: 330, bottom: 40)

            // Maximalist extras: a coffee ring and a couple of doodled stars.
            CoffeeRing().frame(width: 120, height: 120).place(left: 420, top: 30)
            Doodle.star.frame(width: 26, height: 26).foregroundStyle(Tokens.Palette.coral).rotationEffect(.degrees(12)).place(left: 210, top: 210)
            Doodle.star.frame(width: 18, height: 18).foregroundStyle(Tokens.Palette.blue).place(right: 300, top: 300)
            Doodle.squiggle.frame(width: 70, height: 20).foregroundStyle(Tokens.Palette.grape.opacity(0.7)).rotationEffect(.degrees(-8)).place(left: 560, bottom: 56)
        }
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
    }

    private var boardingPass: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BOARDING PASS · AT 207").textStyle(Tokens.Typography.monoCaption.withTracking(1.5)).opacity(0.85)
            Text("LIS → JFK").font(Tokens.Typeface.fredoka(.bold).font(size: 38))
            Text("GATE 14 · SEAT 23A · 14JUN24").textStyle(Tokens.Typography.monoSmall)
        }
        .foregroundStyle(Color.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .frame(width: 290, height: 114, alignment: .topLeading)
        .sticker(Tokens.Palette.blue, borderWidth: Tokens.Stroke.panel, radius: Tokens.Radius.card)
        .shadow(Tokens.Shadows.panel)
    }

    private var ticket: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("ADMIT ONE").textStyle(Tokens.TextStyle(.mono(bold: false), 9, tracking: 1))
                Text("Knicks vs Celtics").textStyle(Tokens.TextStyle(.fredoka(.bold), 20, lineHeight: 1.1))
                Text("SEC 224 · ROW F · 12/03/22").textStyle(Tokens.TextStyle(.mono(bold: false), 9))
            }
            .foregroundStyle(Tokens.Palette.ink)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            Tokens.Palette.coral
                .frame(width: 40)
                .overlay(alignment: .leading) { Perforation(color: Tokens.Palette.ink) }
        }
        .frame(width: 190, height: 92)
        .background(Tokens.Palette.sun)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 20, y: 8))
    }

    private var photoStrip: some View {
        VStack(spacing: 6) {
            Text("M")
                .font(Tokens.Typeface.fredoka(.bold).font(size: 34))
                .foregroundStyle(Color.white)
                .frame(width: 110, height: 84)
                .background(Tokens.Palette.coral)
            Tokens.Palette.coralLight.frame(width: 110, height: 84)
            Tokens.Palette.coral.opacity(0.75).frame(width: 110, height: 84)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 26)
        .background(Color.white)
        .shadow(Tokens.Shadows.panel)
    }

    // MARK: The torn title card

    private var card: some View {
        VStack(spacing: 20) {
            Text("A LIFE SIM STARRING YOUR GROUP CHATS")
                .textStyle(Tokens.Typography.monoSmall.withTracking(2))
                .foregroundStyle(Tokens.Palette.pencil)
            Wordmark(style: Tokens.Typography.heroWordmark)
            Text("Your texts already wrote the story. Now you get to play it.")
                .textStyle(Tokens.Typography.lede)
                .foregroundStyle(Tokens.Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                model.onboarding = .privacy
            } label: {
                HStack(spacing: 10) {
                    Text("get started")
                    Text("→").font(Tokens.Typeface.fredoka(.semibold).font(size: 24))
                }
            }
            .buttonStyle(HardShadowButtonStyle())
            .keyboardShortcut(.defaultAction)
            .padding(.top, 6)
            Text("everything stays on this Mac. promise.")
                .textStyle(Tokens.TextStyle(.caveat(bold: false), 21))
                .foregroundStyle(Tokens.Palette.pencil)
        }
        .padding(.top, 56)
        .padding(.horizontal, 56)
        .padding(.bottom, 50)
        .frame(width: 560)
        .background(TornPaperShape(depth: 0.02).fill(Tokens.Palette.card))
        .shadow(Tokens.Shadows.paperCard)
        .rotationEffect(.degrees(-1.5))
        .offset(y: -8)
        .scaleEffect(appeared ? 1 : 0.9)
        .rotationEffect(.degrees(appeared ? 0 : -4))
    }
}

/// The dashed tear-line between a ticket and its stub.
struct Perforation: View {
    var color: Color
    var vertical = true

    var body: some View {
        LineShape(vertical: vertical)
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            .frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
    }
}
