import RerunCore
import SwiftUI

/// 04 — stickers fly in and stack up while the world builds.
struct BuildingWorldView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    private struct Piece {
        var x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
        var fill: Color, ink: Color
        var title: String, subtitle: String
        var from: CGSize, startTilt: Double, tilt: Double, delay: Double
    }

    private var pieces: [Piece] {
        let people = (model.candidates.isEmpty ? model.includedPeople : model.candidates.filter(\.included))
        func name(_ index: Int, _ fallback: String) -> String { people.indices.contains(index) ? people[index].displayName : fallback }
        func count(_ index: Int, _ fallback: String) -> String {
            guard people.indices.contains(index) else { return fallback }
            let person = people[index]
            return person.momentCount > 0 ? "\(person.momentCount) MOMENTS" : "\(person.messageCount.formatted()) TEXTS"
        }
        return [
            Piece(x: 70, y: 40, width: 150, height: 96, fill: Tokens.Palette.coral, ink: .white, title: name(0, "Maya"), subtitle: count(0, "212 MOMENTS"), from: CGSize(width: -260, height: -140), startTilt: -40, tilt: -8, delay: 0),
            Piece(x: 250, y: 20, width: 170, height: 70, fill: Tokens.Palette.blue, ink: .white, title: "LIS → JFK", subtitle: "BOARDING PASS", from: CGSize(width: 220, height: -200), startTilt: 30, tilt: 5, delay: 0.5),
            Piece(x: 430, y: 70, width: 130, height: 110, fill: Tokens.Palette.sun, ink: Tokens.Palette.ink, title: name(4, "the ducks"), subtitle: count(4, "304 MOMENTS"), from: CGSize(width: 300, height: -60), startTilt: 50, tilt: 9, delay: 1),
            Piece(x: 40, y: 170, width: 160, height: 80, fill: Tokens.Palette.grape, ink: .white, title: "Big Sur ’19", subtitle: "61 MESSAGES", from: CGSize(width: -320, height: 80), startTilt: -30, tilt: 4, delay: 1.5),
            Piece(x: 230, y: 130, width: 170, height: 120, fill: .white, ink: Tokens.Palette.ink, title: "$214.00", subtitle: "RECEIPT · 01/19/24", from: CGSize(width: 0, height: 260), startTilt: 20, tilt: -3, delay: 2),
            Piece(x: 420, y: 210, width: 150, height: 80, fill: Tokens.Palette.leaf, ink: .white, title: name(1, "Dad"), subtitle: count(1, "148 MOMENTS"), from: CGSize(width: 280, height: 200), startTilt: -50, tilt: -6, delay: 2.5),
        ]
    }

    private var fraction: Double { model.buildProgress?.fraction ?? 0.4 }

    private var status: String {
        guard let progress = model.buildProgress else { return "learning that Dad uses full stops. always." }
        return progress.detail ?? progress.phase.rawValue + "…"
    }

    var body: some View {
        ZStack {
            Tokens.Palette.ink
            DotPattern(color: Color.white.opacity(0.08))
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    StepPips(step: 3, color: Tokens.Palette.sun, labelColor: Tokens.Palette.perforation)
                    Text("Building your world…")
                        .font(Tokens.Typeface.fredoka(.bold).font(size: 48))
                        .tracking(-1)
                        .foregroundStyle(Color.white)
                }
                assembling.frame(width: 600, height: 300)
                VStack(spacing: 16) {
                    progressBar
                    HStack(spacing: 0) {
                        Text(status)
                        BlinkingCursor()
                    }
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 16))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .frame(minHeight: 24)
                    .animation(.easeInOut(duration: 0.25), value: status)
                    Text("usually 2–3 minutes. you can close this window — we'll ping you.")
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 22))
                        .foregroundStyle(Tokens.Palette.perforation)
                }
                .frame(width: 520)
            }
            WipBadge().place(right: 56, bottom: 44)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    CandyStripes()
                        .clipShape(Capsule())
                        .frame(width: max(18, geometry.size.width * fraction))
                        .animation(.easeOut(duration: 0.6), value: fraction)
                }
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 2))
            }
            .frame(height: 18)
            Text("\(Int((fraction * 100).rounded()))%")
                .textStyle(Tokens.TextStyle(.mono(bold: false), 14))
                .foregroundStyle(Tokens.Palette.sun)
                .frame(width: 44, alignment: .leading)
        }
    }

    @ViewBuilder
    private var assembling: some View {
        if isRenderingSnapshot {
            ZStack(alignment: .topLeading) {
                ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                    sticker(piece).rotationEffect(.degrees(piece.tilt)).offset(x: piece.x, y: piece.y)
                }
            }
            .frame(width: 600, height: 300, alignment: .topLeading)
        } else {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                        let frame = Self.assemble(time: time - piece.delay, piece: piece)
                        sticker(piece)
                            .scaleEffect(frame.scale)
                            .rotationEffect(.degrees(frame.tilt))
                            .offset(x: piece.x + frame.offset.width, y: piece.y + frame.offset.height)
                            .opacity(frame.opacity)
                    }
                }
                .frame(width: 600, height: 300, alignment: .topLeading)
            }
        }
    }

    private func sticker(_ piece: Piece) -> some View {
        VStack(alignment: .leading) {
            Text(piece.subtitle).textStyle(Tokens.TextStyle(.mono(bold: false), 9, tracking: 1))
            Spacer(minLength: 0)
            Text(piece.title).font(Tokens.Typeface.fredoka(.bold).font(size: 22)).lineLimit(2).minimumScaleFactor(0.7)
        }
        .foregroundStyle(piece.ink)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(width: piece.width - 10, height: piece.height - 10, alignment: .leading)
        .sticker(piece.fill, borderWidth: Tokens.Stroke.panel, radius: Tokens.Radius.card)
        .shadow(Tokens.Shadows.panel)
    }

    /// The mockup's `rr-assemble` keyframes: fly in from `from`, overshoot,
    /// settle, hold, then drift up and fade. Six-second loop.
    private static func assemble(time: Double, piece: Piece) -> (offset: CGSize, tilt: Double, scale: Double, opacity: Double) {
        let t = (time.truncatingRemainder(dividingBy: 6) + 6).truncatingRemainder(dividingBy: 6) / 6
        func ease(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
        switch t {
        case ..<0.18:
            let p = ease(t / 0.18)
            return (CGSize(width: piece.from.width * (1 - p), height: piece.from.height * (1 - p)),
                    piece.startTilt + (piece.tilt - piece.startTilt) * p, 0.6 + 0.46 * p, p)
        case ..<0.24:
            let p = (t - 0.18) / 0.06
            return (.zero, piece.tilt, 1.06 - 0.06 * p, 1)
        case ..<0.86:
            return (.zero, piece.tilt, 1, 1)
        default:
            let p = (t - 0.86) / 0.14
            return (CGSize(width: 0, height: -10 * p), piece.tilt, 1 - 0.04 * p, 1 - p)
        }
    }
}

/// Diagonal coral candy stripes for the progress bar.
struct CandyStripes: View {
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    var body: some View {
        TimelineView(.animation(paused: isRenderingSnapshot)) { timeline in
            let shift = isRenderingSnapshot ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate * 20).truncatingRemainder(dividingBy: 24)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Tokens.Palette.coral))
                var x = -size.height + shift - 24
                while x < size.width + size.height {
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: x, y: size.height))
                    stripe.addLine(to: CGPoint(x: x + size.height, y: 0))
                    stripe.addLine(to: CGPoint(x: x + size.height + 12, y: 0))
                    stripe.addLine(to: CGPoint(x: x + 12, y: size.height))
                    stripe.closeSubpath()
                    context.fill(stripe, with: .color(Color(hex: 0xFF7A62)))
                    x += 24
                }
            }
        }
    }
}

/// ▍ blinking at the end of a line.
struct BlinkingCursor: View {
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot
    @State private var on = true

    var body: some View {
        Text("▍")
            .opacity(on ? 1 : 0.25)
            .onAppear {
                guard !isRenderingSnapshot else { return }
                withAnimation(.easeInOut(duration: 0.6).repeatForever()) { on = false }
            }
    }
}

/// The bobbing "wip!" sticker.
struct WipBadge: View {
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot
    @State private var up = false

    var body: some View {
        Text("wip!")
            .font(Tokens.Typeface.caveat(bold: true).font(size: 20))
            .foregroundStyle(Tokens.Palette.ink)
            .frame(width: 54, height: 54)
            .background(Circle().fill(Tokens.Palette.sun))
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 14, y: 6))
            .rotationEffect(.degrees(up ? 2 : -3))
            .offset(y: up ? -6 : 0)
            .onAppear {
                guard !isRenderingSnapshot else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { up = true }
            }
    }
}

/// A dot grid in any color (white dots on the dark building screen).
struct DotPattern: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            var dots = Path()
            let spacing = Tokens.Metrics.dotGridSpacing, radius = Tokens.Metrics.dotRadius
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    dots.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    x += spacing
                }
                y += spacing
            }
            context.fill(dots, with: .color(color))
        }
        .allowsHitTesting(false)
    }
}
