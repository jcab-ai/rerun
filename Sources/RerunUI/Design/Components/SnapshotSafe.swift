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
            ScrollStandIn(axes: axes, anchor: anchor) { content }
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

/// Lays out like a ScrollView without being one: the content gets its ideal
/// size along the scrolling axes, the container takes whatever it's offered
/// along them, and the content is pinned to `anchor`.
struct ScrollStandIn: Layout {
    var axes: Axis.Set
    var anchor: Alignment

    private func childProposal(_ proposal: ProposedViewSize) -> ProposedViewSize {
        ProposedViewSize(
            width: axes.contains(.horizontal) ? nil : proposal.width,
            height: axes.contains(.vertical) ? nil : proposal.height
        )
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let size = child.sizeThatFits(childProposal(proposal))
        return CGSize(
            width: axes.contains(.horizontal) ? (proposal.width ?? size.width) : size.width,
            height: axes.contains(.vertical) ? (proposal.height ?? size.height) : size.height
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        let size = child.sizeThatFits(childProposal(proposal))
        let x: CGFloat = switch anchor.horizontal {
        case .trailing: bounds.maxX - size.width
        case .center: bounds.midX - size.width / 2
        default: bounds.minX
        }
        let y: CGFloat = switch anchor.vertical {
        case .bottom: bounds.maxY - size.height
        case .center: bounds.midY - size.height / 2
        default: bounds.minY
        }
        child.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
    }
}
