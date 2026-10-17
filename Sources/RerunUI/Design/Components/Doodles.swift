import SwiftUI

// Hand-drawn extras that make the desk feel lived-in: sparkles, squiggles,
// arrows, coffee rings, paper clips, postmarks.

public enum Doodle {
    /// ✦ a four-point sparkle.
    public static var star: some View { SparkleShape() }

    /// A loose wavy underline.
    public static var squiggle: some View {
        SquiggleShape().stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    /// A curved hand-drawn arrow pointing right.
    public static var arrow: some View {
        ArrowShape().stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }

    /// Three short motion lines.
    public static var whoosh: some View {
        WhooshShape().stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
}

public struct SparkleShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let pinch = r * 0.18
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + pinch, y: c.y - pinch))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + pinch, y: c.y + pinch))
        path.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - pinch, y: c.y + pinch))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - pinch, y: c.y - pinch))
        path.closeSubpath()
        return path
    }
}

public struct SquiggleShape: Shape {
    public var waves: Int = 4

    public init(waves: Int = 4) {
        self.waves = waves
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / CGFloat(waves * 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for index in 0..<(waves * 2) {
            let x = rect.minX + step * CGFloat(index + 1)
            let y = index.isMultiple(of: 2) ? rect.minY : rect.maxY
            path.addQuadCurve(to: CGPoint(x: x, y: rect.midY), control: CGPoint(x: x - step / 2, y: y))
        }
        return path
    }
}

public struct ArrowShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX, y: rect.maxY * 0.7)
        let end = CGPoint(x: rect.maxX - 2, y: rect.midY)
        path.move(to: start)
        path.addQuadCurve(to: end, control: CGPoint(x: rect.midX, y: rect.minY))
        path.move(to: CGPoint(x: end.x - 9, y: end.y - 7))
        path.addLine(to: end)
        path.addLine(to: CGPoint(x: end.x - 10, y: end.y + 6))
        return path
    }
}

public struct WhooshShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        for (index, fraction) in [0.2, 0.5, 0.8].enumerated() {
            let y = rect.minY + rect.height * fraction
            let inset = CGFloat(index == 1 ? 0 : 6)
            path.move(to: CGPoint(x: rect.minX + inset, y: y))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: y))
        }
        return path
    }
}

/// A vertical or horizontal line, for dashed rules.
public struct LineShape: Shape {
    public var vertical: Bool

    public init(vertical: Bool = false) {
        self.vertical = vertical
    }

    public func path(in rect: CGRect) -> Path {
        Path { path in
            if vertical {
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

/// A faint coffee ring left on the desk.
public struct CoffeeRing: View {
    public init() {}

    public var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0x8C5A2B).opacity(0.07), lineWidth: 7)
            Circle().stroke(Color(hex: 0x8C5A2B).opacity(0.05), lineWidth: 2).padding(6)
            Circle()
                .trim(from: 0.05, to: 0.35)
                .stroke(Color(hex: 0x8C5A2B).opacity(0.08), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .padding(-3)
        }
        .allowsHitTesting(false)
    }
}

/// A silver paper clip.
public struct PaperClip: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: 7)
            .stroke(Color(hex: 0x9A9AA6), lineWidth: 2.5)
            .frame(width: 14, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(hex: 0xB8B8C2), lineWidth: 2)
                    .frame(width: 8, height: 28)
                    .offset(y: 4)
            )
            .shadow(Tokens.Shadow(Color.black.opacity(0.18), blur: 2, x: 1, y: 1))
    }
}

/// A round postmark: "RERUN · LOCAL ONLY · 2026".
public struct Postmark: View {
    var top: String
    var middle: String
    var bottom: String
    var color: Color

    public init(top: String, middle: String, bottom: String, color: Color = Tokens.Palette.ink) {
        self.top = top
        self.middle = middle
        self.bottom = bottom
        self.color = color
    }

    public var body: some View {
        VStack(spacing: 1) {
            Text(top).textStyle(Tokens.TextStyle(.mono(bold: true), 7, tracking: 1))
            Text(middle).font(Tokens.Typeface.fredoka(.bold).font(size: 13))
            Text(bottom).textStyle(Tokens.TextStyle(.mono(bold: false), 7, tracking: 1))
        }
        .foregroundStyle(color)
        .frame(width: 64, height: 64)
        .overlay(Circle().strokeBorder(color, lineWidth: 2))
        .overlay(Circle().strokeBorder(color, lineWidth: 1).padding(4))
        .opacity(0.32)
        .allowsHitTesting(false)
    }
}
