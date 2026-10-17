import AppKit
import SwiftUI

/// The 30pt kraft title bar drawn under the system traffic lights
/// (the window uses `.hiddenTitleBar`).
public struct WindowTitleBar: View {
    var title: String
    var background: Color
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    public init(_ title: String, background: Color = Tokens.Palette.kraft) {
        self.title = title
        self.background = background
    }

    public var body: some View {
        ZStack {
            background
            if !isRenderingSnapshot {
                WindowDragArea()
            }
            Text(title)
                .textStyle(Tokens.Typography.windowTitle)
                .foregroundStyle(Tokens.Palette.inkMuted)
                .lineLimit(1)
                .allowsHitTesting(false)
        }
        .frame(height: Tokens.Metrics.titleBarHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Tokens.Palette.hairline).frame(height: Tokens.Stroke.hairline)
        }
    }
}

/// Lets the custom title bar move the window, and zoom it on double-click.
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                window?.performZoom(nil)
            } else {
                window?.performDrag(with: event)
            }
        }
    }
}

private struct SnapshotRenderingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when a view is rendered offscreen with `ImageRenderer`, which can't
    /// draw AppKit-backed views; those are left out.
    public var isRenderingSnapshot: Bool {
        get { self[SnapshotRenderingKey.self] }
        set { self[SnapshotRenderingKey.self] = newValue }
    }
}
