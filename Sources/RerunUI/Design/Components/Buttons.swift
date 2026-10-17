import SwiftUI

/// The mockup's primary button: a colored pill with a 3pt ink outline sitting
/// on a hard 5pt ink shadow. Hover lifts it 2pt (shadow grows to 7pt); press
/// pushes it down onto the shadow.
public struct HardShadowButtonStyle: ButtonStyle {
    var fill: Color
    var foreground: Color
    var text: Tokens.TextStyle
    var padding: EdgeInsets
    var cornerRadius: CGFloat
    var shadowOffset: CGFloat
    var tilt: Double

    public init(
        fill: Color = Tokens.Palette.coral,
        foreground: Color = .white,
        text: Tokens.TextStyle = Tokens.Typography.buttonLarge,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 34, bottom: 16, trailing: 34),
        cornerRadius: CGFloat = 999,
        shadowOffset: CGFloat = Tokens.Shadows.hardOffset,
        tilt: Double = 0
    ) {
        self.fill = fill
        self.foreground = foreground
        self.text = text
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowOffset = shadowOffset
        self.tilt = tilt
    }

    /// The choice cards on the play screen.
    public static func choice(_ fill: Color, tilt: Double) -> HardShadowButtonStyle {
        HardShadowButtonStyle(
            fill: fill,
            text: Tokens.Typography.choice,
            padding: EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18),
            cornerRadius: Tokens.Radius.choice,
            shadowOffset: Tokens.Shadows.hardOffsetSmall,
            tilt: tilt
        )
    }

    public func makeBody(configuration: Configuration) -> some View {
        HardShadowButton(configuration: configuration, style: self)
    }

    private struct HardShadowButton: View {
        let configuration: Configuration
        let style: HardShadowButtonStyle
        @State private var hovering = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: style.cornerRadius)
            let lifted = hovering && isEnabled && !configuration.isPressed
            // The shadow's far edge stays put; the button moves over it.
            let shift: CGFloat = configuration.isPressed ? style.shadowOffset - 1 : (lifted ? -2 : 0)
            let shadow = style.shadowOffset - shift

            configuration.label
                .textStyle(style.text)
                .foregroundStyle(style.foreground)
                .padding(style.padding)
                .padding(Tokens.Stroke.button)
                .background(shape.fill(style.fill))
                .overlay(shape.strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.button))
                .background(shape.fill(Tokens.Palette.ink).offset(x: shadow, y: shadow))
                .offset(x: shift, y: shift)
                .rotationEffect(.degrees(style.tilt))
                .opacity(isEnabled ? 1 : 0.55)
                .contentShape(shape)
                .onHover { hovering = $0 }
                .animation(.easeOut(duration: 0.12), value: lifted)
                .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
        }
    }
}

/// White pill with an ink outline (Settings actions, "← world map").
public struct OutlinePillButtonStyle: ButtonStyle {
    var fill: Color
    var text: Tokens.TextStyle

    public init(fill: Color = .white, text: Tokens.TextStyle = Tokens.Typography.pill) {
        self.fill = fill
        self.text = text
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(text)
            .foregroundStyle(Tokens.Palette.ink)
            .padding(.vertical, 9)
            .padding(.horizontal, 18)
            .padding(Tokens.Stroke.outline)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.outline))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Capsule())
    }
}

/// Underlined text link ("not now", "+ add context").
public struct UnderlineLinkButtonStyle: ButtonStyle {
    var text: Tokens.TextStyle
    var color: Color

    public init(text: Tokens.TextStyle = Tokens.Typography.link, color: Color = Tokens.Palette.ink) {
        self.text = text
        self.color = color
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(text)
            .underline(true, color: color)
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
