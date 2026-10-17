import RerunCore
import SwiftUI

/// 11 — the three "something's off" cards: no conversations, locked, lost in the mail.
struct EmptyStateCard<Art: View>: View {
    var title: String
    var message: String
    var primary: String
    var primaryFill: Color
    var primaryInk: Color
    var primaryAction: @MainActor () -> Void
    var secondary: String?
    var secondaryAction: (@MainActor () -> Void)?
    @ViewBuilder var art: Art

    var body: some View {
        VStack(spacing: 16) {
            art.padding(.bottom, 8)
            Text(title)
                .textStyle(Tokens.TextStyle(.fredoka(.bold), 30, lineHeight: 1.05))
                .foregroundStyle(Tokens.Palette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .textStyle(Tokens.TextStyle(.fredoka(.regular), 16, lineHeight: 1.45))
                .foregroundStyle(Tokens.Palette.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(primary, action: primaryAction)
                    .buttonStyle(HardShadowButtonStyle(
                        fill: primaryFill,
                        foreground: primaryInk,
                        text: Tokens.TextStyle(.fredoka(.semibold), 16),
                        padding: EdgeInsets(top: 11, leading: 22, bottom: 11, trailing: 22),
                        shadowOffset: Tokens.Shadows.hardOffsetSmall
                    ))
                    .keyboardShortcut(.defaultAction)
                if let secondary, let secondaryAction {
                    Button(secondary, action: secondaryAction)
                        .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.regular), 15)))
                }
            }
            .padding(.top, 4)
        }
        .frame(width: 480)
    }
}

/// A blue speech bubble with "…" — nothing to read yet.
struct ChatBubbleArt: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // The tail sits behind the bubble so only its outer edges show.
            UnevenRoundedRectangle(bottomLeadingRadius: 12)
                .fill(Tokens.Palette.blue)
                .overlay(UnevenRoundedRectangle(bottomLeadingRadius: 12).strokeBorder(Color.white, lineWidth: 6))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-20))
                .offset(x: 14, y: 16)
            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 14, height: 14)
                Circle().fill(Color.white.opacity(0.7)).frame(width: 14, height: 14)
                Circle().fill(Color.white.opacity(0.4)).frame(width: 14, height: 14)
            }
            .frame(width: 118, height: 84)
            .sticker(Tokens.Palette.blue, borderWidth: 6, radius: 40)
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 20, y: 10))
        }
        .overlay(alignment: .topTrailing) {
            Tape(Color(.sRGB, red: 255 / 255, green: 236 / 255, blue: 170 / 255, opacity: 0.88), width: 60, height: 20, angle: 30).offset(x: 6, y: -10)
        }
        .rotationEffect(.degrees(-8))
    }
}

/// A yellow padlock labelled "locked".
struct PadlockArt: View {
    var body: some View {
        VStack(spacing: -6) {
            ZStack {
                ShackleShape().stroke(Color.white, style: StrokeStyle(lineWidth: 13, lineCap: .butt))
                ShackleShape().stroke(Tokens.Palette.sun, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
            }
            .frame(width: 70, height: 52)
            Text("locked")
                .font(Tokens.Typeface.caveat(bold: true).font(size: 30))
                .foregroundStyle(Tokens.Palette.ink)
                .frame(width: 110, height: 86)
                .sticker(Tokens.Palette.sun, borderWidth: 6, radius: 18)
        }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 14, y: 10))
        .rotationEffect(.degrees(7))
    }

    struct ShackleShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + 6, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.midX - rect.minX - 6, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.maxY))
            return path
        }
    }
}

/// A coral envelope stamped RETURN TO SENDER.
struct EnvelopeArt: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .top) {
                Tokens.Palette.coral
                FlapShape().fill(Color(hex: 0xFF7A62)).frame(height: 50)
            }
            Text("RETURN TO SENDER")
                .textStyle(Tokens.TextStyle(.mono(bold: false), 10))
                .foregroundStyle(Color.white)
                .padding(.trailing, 12)
                .padding(.bottom, 10)
        }
        .frame(width: 138, height: 84)
        .sticker(Tokens.Palette.coral, borderWidth: 6, radius: 10)
        .overlay(alignment: .topTrailing) {
            Rectangle()
                .fill(Tokens.Palette.leaf)
                .frame(width: 36, height: 42)
                .overlay(Rectangle().strokeBorder(Color.white, style: StrokeStyle(lineWidth: 3, dash: [4, 3])))
                .rotationEffect(.degrees(12))
                .offset(x: 10, y: -12)
        }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 14, y: 10))
        .rotationEffect(.degrees(-5))
    }

    struct FlapShape: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX - 10, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX + 10, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                path.closeSubpath()
            }
        }
    }
}

/// Full-window onboarding state for "no conversations" and "locked".
struct OnboardingProblemView: View {
    @EnvironmentObject private var model: AppModel
    let step: OnboardingStep
    @State private var showsSyncHelp = false

    var body: some View {
        ZStack {
            DotGrid()
            deskScatter
            if step == .locked {
                EmptyStateCard(
                    title: "rerun can't open Messages",
                    message: "macOS keeps the Messages library locked until you allow it. Open System Settings → Privacy & Security → Full Disk Access, and switch rerun on. Nothing leaves this Mac.",
                    primary: "Open System Settings",
                    primaryFill: Tokens.Palette.sun,
                    primaryInk: Tokens.Palette.ink,
                    primaryAction: model.openFullDiskAccessSettings,
                    secondary: "I did it — check again",
                    secondaryAction: model.requestMessagesAccess
                ) { PadlockArt() }
            } else {
                EmptyStateCard(
                    title: "No conversations found yet",
                    message: "Your Messages library looks empty on this Mac. If you just turned on Messages in iCloud, it can take a while to download — leave Messages open for a bit, then scan again.",
                    primary: "Scan again",
                    primaryFill: Tokens.Palette.blue,
                    primaryInk: .white,
                    primaryAction: model.requestMessagesAccess,
                    secondary: "how to sync Messages",
                    secondaryAction: { showsSyncHelp = true }
                ) { ChatBubbleArt() }
                .popover(isPresented: $showsSyncHelp, arrowEdge: .bottom) { syncHelp }
            }
            Button("explore the sample world instead") { model.skipOnboarding() }
                .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.caveat(bold: false), 20), color: Tokens.Palette.pencil))
                .place(bottom: 36)
                .frame(maxWidth: .infinity)
        }
    }

    /// A few doodles so even a dead end looks like somebody's desk.
    private var deskScatter: some View {
        ZStack {
            Doodle.star.foregroundStyle(Tokens.Palette.coral).frame(width: 22, height: 22)
                .place(left: 210, top: 170)
            Doodle.star.foregroundStyle(Tokens.Palette.blue).frame(width: 15, height: 15)
                .place(right: 250, top: 250)
            Doodle.star.foregroundStyle(Tokens.Palette.sun).frame(width: 12, height: 12)
                .place(left: 300, bottom: 230)
            Doodle.squiggle.foregroundStyle(Tokens.Palette.grape.opacity(0.7)).frame(width: 70, height: 14)
                .rotationEffect(.degrees(-6))
                .place(right: 230, bottom: 190)
            CoffeeRing()
                .frame(width: 120, height: 120)
                .place(left: 120, bottom: 90)
            Text(step == .locked ? "we'll wait ✦" : "it's quiet in here…")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 22))
                .foregroundStyle(Tokens.Palette.pencil)
                .rotationEffect(.degrees(6))
                .place(right: 170, top: 160)
        }
        .allowsHitTesting(false)
    }

    private var syncHelp: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SYNCING MESSAGES").textStyle(Tokens.Typography.monoEyebrow).foregroundStyle(Tokens.Palette.pencil)
            Text("1. Open Messages → Settings → iMessage.\n2. Turn on “Enable Messages in iCloud”.\n3. Leave Messages open while it downloads.\n4. Come back and scan again.")
                .textStyle(Tokens.TextStyle(.fredoka(.regular), 15, lineHeight: 1.5))
                .foregroundStyle(Tokens.Palette.ink)
        }
        .padding(18)
        .frame(width: 320, alignment: .leading)
        .background(Tokens.Palette.card)
    }
}
