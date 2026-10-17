import SwiftUI

extension View {
    /// A sticker: colored fill inside a white (or colored) border.
    /// The border sits outside `content`'s padding, like the mockup's CSS borders.
    public func sticker(
        _ fill: Color,
        border: Color = .white,
        borderWidth: CGFloat = Tokens.Stroke.sticker,
        radius: CGFloat = Tokens.Radius.sticker
    ) -> some View {
        padding(borderWidth)
            .background(RoundedRectangle(cornerRadius: radius).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(border, lineWidth: borderWidth))
    }

    /// A dashed pencil box, as used for fine print and "add" affordances.
    public func dashedBox(
        color: Color = Tokens.Palette.pencilLine,
        lineWidth: CGFloat = Tokens.Stroke.dashed,
        radius: CGFloat = Tokens.Radius.note
    ) -> some View {
        padding(lineWidth)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, dash: [lineWidth * 3, lineWidth * 2]))
            )
    }
}

/// "[rerun]" with the coral and blue brackets.
public struct Wordmark: View {
    var style: Tokens.TextStyle

    public init(style: Tokens.TextStyle = Tokens.Typography.wordmark) {
        self.style = style
    }

    public var body: some View {
        (Text("[").foregroundStyle(Tokens.Palette.coral)
            + Text("rerun").foregroundStyle(Tokens.Palette.ink)
            + Text("]").foregroundStyle(Tokens.Palette.blue))
            .textStyle(style)
            .fixedSize()
            .accessibilityLabel("rerun")
    }
}

/// A rounded filter chip: ink when selected, outlined in a person's color otherwise.
public struct FilterChip: View {
    var label: String
    var color: Color
    var isSelected: Bool
    var action: () -> Void

    public init(_ label: String, color: Color = Tokens.Palette.ink, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .textStyle(Tokens.Typography.chip)
                .padding(.vertical, isSelected ? 6 : 6 + Tokens.Stroke.chip)
                .padding(.horizontal, isSelected ? 12 : 12 + Tokens.Stroke.chip)
                .foregroundStyle(isSelected ? Color.white : Tokens.Palette.ink)
                .background(Capsule().fill(isSelected ? Tokens.Palette.ink : Color.clear))
                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : color, lineWidth: Tokens.Stroke.chip))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Small rounded mono tag, e.g. the "+48" bubbles on the map.
public struct CountTag: View {
    var text: String
    var fill: Color
    var foreground: Color

    public init(_ text: String, fill: Color, foreground: Color) {
        self.text = text
        self.fill = fill
        self.foreground = foreground
    }

    public var body: some View {
        Text(text)
            .textStyle(Tokens.Typography.monoCaption)
            .foregroundStyle(foreground)
            .padding(.vertical, 1)
            .padding(.horizontal, 5)
            .background(RoundedRectangle(cornerRadius: Tokens.Radius.tag).fill(fill))
            .fixedSize()
    }
}
