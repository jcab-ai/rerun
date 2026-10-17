import RerunCore
import SwiftUI

// Physical bits of paper the mockup scatters everywhere: receipts, bubbles,
// polaroid strips, tickets, pushpins and stamps.

extension View {
    /// Pins a view to edges of its container, like CSS absolute positioning.
    /// Apply rotation before this so it turns around its own center.
    public func place(left: CGFloat? = nil, right: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        let horizontal: HorizontalAlignment = right != nil && left == nil ? .trailing : .leading
        let vertical: VerticalAlignment = bottom != nil && top == nil ? .bottom : .top
        return padding(EdgeInsets(top: top ?? 0, leading: left ?? 0, bottom: bottom ?? 0, trailing: right ?? 0))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: horizontal, vertical: vertical))
    }
}

extension PersonColor {
    /// Three tiles of a polaroid strip: the color, then two lighter washes.
    public var shades: [Color] {
        switch self {
        case .coral: [Tokens.Palette.coral, Color(hex: 0xFF7A62), Color(hex: 0xFF9A82)]
        case .blue: [Tokens.Palette.blue, Color(hex: 0x5479FF), Color(hex: 0x7E99FF)]
        case .leaf: [Tokens.Palette.leaf, Color(hex: 0x52C676), Color(hex: 0x7DD597)]
        case .grape: [Tokens.Palette.grape, Color(hex: 0xA170FF), Color(hex: 0xB994FF)]
        case .sun: [Tokens.Palette.sun, Color(hex: 0xFFD25C), Color(hex: 0xFFDF85)]
        }
    }

    /// The washi tape that pairs with this color on polaroids.
    public var tape: Color {
        switch self {
        case .coral, .grape: Tokens.Palette.tapeYellow
        case .blue, .sun: Tokens.Palette.tapeBlue
        case .leaf: Tokens.Palette.tapePink
        }
    }
}

/// A receipt's torn, zig-zag bottom edge (and optional top).
public struct ZigzagShape: Shape {
    var teeth: Int
    var depth: CGFloat

    public init(teeth: Int = 10, depth: CGFloat = 8) {
        self.teeth = teeth
        self.depth = depth
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - depth))
        let step = rect.width / CGFloat(teeth * 2)
        for index in (0..<(teeth * 2)).reversed() {
            let x = rect.minX + step * CGFloat(index)
            path.addLine(to: CGPoint(x: x, y: index.isMultiple(of: 2) ? rect.maxY - depth : rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

/// A thermal-paper receipt: monospaced lines, dashed rules, torn bottom.
public struct ReceiptPaper<Content: View>: View {
    var width: CGFloat
    var fontSize: CGFloat
    var lineHeight: CGFloat
    var padding: EdgeInsets
    var teeth: Int
    @ViewBuilder var content: Content

    public init(width: CGFloat, fontSize: CGFloat = 10, lineHeight: CGFloat = 1.7, padding: EdgeInsets = EdgeInsets(top: 12, leading: 14, bottom: 22, trailing: 14), teeth: Int = 10, @ViewBuilder content: () -> Content) {
        self.width = width
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.padding = padding
        self.teeth = teeth
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .textStyle(Tokens.TextStyle(.mono(bold: false), fontSize, lineHeight: lineHeight))
            .foregroundStyle(Tokens.Palette.ink)
            .padding(padding)
            .frame(width: width, alignment: .leading)
            .background(ZigzagShape(teeth: teeth, depth: 7).fill(Color.white))
    }
}

/// "omakase x2 ........ 190.00"
public struct ReceiptLine: View {
    var label: String
    var amount: String?
    var bold: Bool

    public init(_ label: String, _ amount: String? = nil, bold: Bool = false) {
        self.label = label
        self.amount = amount
        self.bold = bold
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(label).lineLimit(1)
            if let amount {
                DottedLeader().frame(height: 2).padding(.top, 6)
                Text(amount)
            }
        }
        .fontWeight(bold ? .bold : .regular)
    }
}

/// The dotted fill between a label and its price.
public struct DottedLeader: View {
    var color: Color = Tokens.Palette.ink

    public var body: some View {
        LineShape()
            .stroke(color, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [0.5, 3.5]))
    }
}

/// A dashed rule across a receipt.
public struct DashedRule: View {
    var color: Color = Tokens.Palette.ink

    public init(color: Color = Tokens.Palette.ink) {
        self.color = color
    }

    public var body: some View {
        LineShape()
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            .frame(height: 1)
    }
}

/// An iMessage-style bubble as a sticker (thick white border, slight tilt).
public struct BubbleSticker: View {
    var text: String
    var fromMe: Bool
    var fontSize: CGFloat
    var tilt: Double

    public init(_ text: String, fromMe: Bool = false, fontSize: CGFloat = 16, tilt: Double = 0) {
        self.text = text
        self.fromMe = fromMe
        self.fontSize = fontSize
        self.tilt = tilt
    }

    public var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundStyle(fromMe ? Color.white : Tokens.Palette.ink)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 20).fill(fromMe ? Color(hex: 0x1F8BFF) : Tokens.Palette.Messages.bubbleThem))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white, lineWidth: 4))
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.18), blur: 16, y: 6))
            .rotationEffect(.degrees(tilt))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A red map pin, viewed from above.
public struct PushPin: View {
    var size: CGFloat

    public init(size: CGFloat = 24) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Tokens.Palette.coralLight, Tokens.Palette.coralDeep], center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: size * 0.7))
            .overlay(Circle().fill(Color.white.opacity(0.55)).frame(width: size * 0.22, height: size * 0.22).offset(x: -size * 0.16, y: -size * 0.16))
            .frame(width: size, height: size)
            .shadow(Tokens.Shadow(Color.black.opacity(0.35), blur: 6, y: 4))
    }
}

/// A rubber stamp ("MISSED", "PAID").
public struct RubberStamp: View {
    var text: String
    var color: Color
    var size: CGFloat
    var tilt: Double

    public init(_ text: String, color: Color = Tokens.Palette.coral, size: CGFloat = 30, tilt: Double = -14) {
        self.text = text
        self.color = color
        self.size = size
        self.tilt = tilt
    }

    public var body: some View {
        Text(text)
            .font(Tokens.Typeface.fredoka(.bold).font(size: size))
            .tracking(size / 15)
            .foregroundStyle(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 14)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 4))
            .opacity(0.9)
            .rotationEffect(.degrees(tilt))
            .fixedSize()
    }
}

/// A barcode made of uneven bars.
public struct Barcode: View {
    var color: Color = Tokens.Palette.ink

    public init(color: Color = Tokens.Palette.ink) {
        self.color = color
    }

    public var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            var index = 0
            let pattern: [CGFloat] = [2, 1, 1, 2, 3, 1, 1, 1, 2, 2, 1, 3]
            while y < size.height {
                let bar = pattern[index % pattern.count]
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: bar)), with: .color(color))
                y += bar + pattern[(index + 5) % pattern.count] + 1
                index += 1
            }
        }
    }
}

/// A photo-booth strip: three tiles in a person's color, a handwritten caption,
/// washi tape on top, and an optional ✓ badge.
public struct PolaroidStrip: View {
    var person: Person
    var tileSize: CGSize
    var caption: String
    var captionSize: CGFloat
    var check: Bool?
    var showsTape: Bool

    public init(person: Person, tileSize: CGSize = CGSize(width: 112, height: 80), caption: String? = nil, captionSize: CGFloat = 22, check: Bool? = nil, showsTape: Bool = true) {
        self.person = person
        self.tileSize = tileSize
        self.caption = caption ?? person.displayName
        self.captionSize = captionSize
        self.check = check
        self.showsTape = showsTape
    }

    public var body: some View {
        let shades = person.color.shades
        let onFill = person.color.onFill
        VStack(spacing: 5) {
            ZStack {
                shades[0]
                Text(person.isGroup ? person.shortName : person.initial)
                    .font(Tokens.Typeface.fredoka(.bold).font(size: person.isGroup ? tileSize.height * 0.33 : tileSize.height * 0.5))
                    .foregroundStyle(onFill)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 4)
            }
            .frame(width: tileSize.width, height: tileSize.height)
            ZStack {
                shades[1]
                if person.isGroup && !person.members.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(Array(person.members.prefix(4).enumerated()), id: \.offset) { _, name in
                            Text(String(name.prefix(1)).uppercased())
                                .font(Tokens.Typeface.fredoka(.bold).font(size: tileSize.height * 0.2))
                                .foregroundStyle(onFill)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(width: tileSize.width, height: tileSize.height)
            shades[2].frame(width: tileSize.width, height: tileSize.height)
        }
        .padding(.horizontal, 7)
        .padding(.top, 7)
        .padding(.bottom, captionSize + 8)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Text(caption)
                .font(Tokens.Typeface.caveat(bold: true).font(size: captionSize))
                .foregroundStyle(Tokens.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
        .overlay(alignment: .topTrailing) {
            if let check {
                CheckBadge(checked: check)
                    .offset(x: 14, y: 8)
            }
        }
        .overlay(alignment: .topLeading) {
            if showsTape {
                Tape(person.color.tape, width: tileSize.width * 0.62, height: 22, angle: -6)
                    .offset(x: tileSize.width * 0.27, y: -12)
            }
        }
    }
}

/// Green ✓ in a white ring, or an empty dashed circle.
public struct CheckBadge: View {
    var checked: Bool

    public init(checked: Bool) {
        self.checked = checked
    }

    public var body: some View {
        Group {
            if checked {
                Text("✓")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 16))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Tokens.Palette.leaf))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 3))
                    .shadow(Tokens.Shadow(Color.black.opacity(0.2), blur: 8, y: 3))
            } else {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().strokeBorder(Tokens.Palette.pencilLine, style: StrokeStyle(lineWidth: 3, dash: [4, 3])))
                    .frame(width: 32, height: 32)
            }
        }
    }
}

/// "▬ ▬ ▭  STEP 2 OF 3"
public struct StepPips: View {
    var step: Int
    var total: Int
    var color: Color
    var offColor: Color
    var labelColor: Color

    public init(step: Int, total: Int = 3, color: Color = Tokens.Palette.coral, offColor: Color = Tokens.Palette.ink.opacity(0.15), labelColor: Color = Tokens.Palette.pencil) {
        self.step = step
        self.total = total
        self.color = color
        self.offColor = offColor
        self.labelColor = labelColor
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < step ? color : offColor)
                    .frame(width: 28, height: 8)
            }
            Text("STEP \(step) OF \(total)")
                .textStyle(Tokens.Typography.monoSmall.withTracking(1))
                .foregroundStyle(labelColor)
                .padding(.leading, 6)
        }
    }
}

/// A big colored info sticker (privacy cards, chapter card).
public struct PanelSticker<Content: View>: View {
    var fill: Color
    var width: CGFloat?
    var padding: CGFloat
    var radius: CGFloat
    @ViewBuilder var content: Content

    public init(_ fill: Color, width: CGFloat? = nil, padding: CGFloat = 24, radius: CGFloat = Tokens.Radius.panel, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.width = width
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(padding)
            .frame(width: width.map { $0 - Tokens.Stroke.panel * 2 }, alignment: .leading)
            .sticker(fill, borderWidth: Tokens.Stroke.panel, radius: radius)
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 26, y: 12))
    }
}
