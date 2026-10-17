import SwiftUI

// `ImageRenderer` (used for the screen snapshots in CI) can't draw views that
// AppKit backs — scroll views, text fields, menus. These wrappers use the real
// control in the app and a plain SwiftUI stand-in when rendering a snapshot.

/// A ScrollView that renders as clipped static content in snapshots.
struct AdaptiveScroll<Content: View>: View {
    var axes: Axis.Set = .vertical
    var showsIndicators = true
    var anchor: Alignment = .topLeading
    @ViewBuilder var content: Content
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    var body: some View {
        if isRenderingSnapshot {
            content
                .fixedSize(horizontal: axes.contains(.horizontal), vertical: axes.contains(.vertical))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: anchor)
                .clipped()
        } else {
            ScrollView(axes, showsIndicators: showsIndicators) { content }
        }
    }
}

/// A one-line or growing text field that renders as its text (or prompt) in snapshots.
struct AdaptiveTextField: View {
    var placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var placeholderColor: Color = Tokens.Palette.pencil.opacity(0.7)
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    var body: some View {
        if isRenderingSnapshot {
            Text(text.isEmpty ? placeholder : text)
                .foregroundStyle(text.isEmpty ? placeholderColor : Tokens.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(placeholderColor), axis: axis)
                .textFieldStyle(.plain)
        }
    }
}
