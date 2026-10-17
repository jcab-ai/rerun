import SwiftUI

/// The faint dot grid behind every canvas: 1px ink dots every 16pt.
public struct DotGrid: View {
    var spacing = Tokens.Metrics.dotGridSpacing
    var radius = Tokens.Metrics.dotRadius
    var color = Tokens.Palette.dotGrid

    public init() {}

    public var body: some View {
        Canvas { context, size in
            var dots = Path()
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
        .background(Tokens.Palette.paper)
        .allowsHitTesting(false)
    }
}

/// Kraft paper: a tan base with fine horizontal fibre stripes (2pt every 5–6pt).
public struct KraftPaper: View {
    var color = Tokens.Palette.kraft
    var fibre = Tokens.Palette.kraftFibre
    var period: CGFloat = 5

    public init(period: CGFloat = 5, fibre: Color = Tokens.Palette.kraftFibre) {
        self.period = period
        self.fibre = fibre
    }

    public var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
            var stripes = Path()
            var y = size.height - 2
            while y > -2 {
                stripes.addRect(CGRect(x: 0, y: y, width: size.width, height: 2))
                y -= period
            }
            context.fill(stripes, with: .color(fibre))
        }
        .allowsHitTesting(false)
    }
}

/// A rectangle whose right edge is torn, like the sidebar's kraft strip.
/// Points are the mockup's clip-path: (inset from the right edge, fraction down).
public struct TornEdgeShape: Shape {
    static let tears: [(CGFloat, CGFloat)] = [
        (8, 0.04), (0, 0.08), (6, 0.12), (0, 0.17), (9, 0.21), (0, 0.26), (5, 0.30), (0, 0.35),
        (8, 0.40), (0, 0.45), (6, 0.50), (0, 0.55), (9, 0.60), (0, 0.65), (5, 0.70), (0, 0.75),
        (8, 0.80), (0, 0.85), (6, 0.90), (0, 0.95), (7, 1.00),
    ]

    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        for (inset, fraction) in Self.tears {
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * fraction))
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A sheet torn along its top and bottom edges (welcome card, moment detail).
/// `depth` is how deep the tears go as a fraction of the height (mockup: 1.5–2%).
public struct TornPaperShape: Shape {
    var depth: CGFloat

    // Tear depths at 5% steps across the page, relative to `depth`.
    static let top: [CGFloat] = [1, 0, 0.75, 0, 1, 0.25, 1, 0, 0.75, 0.25, 1, 0, 0.75, 0.25, 1, 0, 0.75, 0.25, 1, 0, 0.75]
    static let bottom: [CGFloat] = [0.75, 0, 1, 0.25, 1, 0, 0.75, 0, 1, 0.25, 1, 0, 0.75, 0, 1, 0.25, 1, 0, 0.75, 0, 1]

    public init(depth: CGFloat = 0.02) {
        self.depth = depth
    }

    public func path(in rect: CGRect) -> Path {
        let tear = rect.height * depth
        let steps = CGFloat(Self.top.count - 1)
        var path = Path()
        for (index, amount) in Self.top.enumerated() {
            let point = CGPoint(x: rect.minX + rect.width * CGFloat(index) / steps, y: rect.minY + tear * amount)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        for (index, amount) in Self.bottom.enumerated().reversed() {
            path.addLine(to: CGPoint(x: rect.minX + rect.width * CGFloat(index) / steps, y: rect.maxY - tear * amount))
        }
        path.closeSubpath()
        return path
    }
}

/// A strip of washi tape.
public struct Tape: View {
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var angle: Double

    public init(_ color: Color = Tokens.Palette.tapeYellow, width: CGFloat = 80, height: CGFloat = 24, angle: Double) {
        self.color = color
        self.width = width
        self.height = height
        self.angle = angle
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle))
            .allowsHitTesting(false)
    }
}
