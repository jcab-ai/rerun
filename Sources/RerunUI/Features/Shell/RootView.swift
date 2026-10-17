import RerunCore
import SwiftUI

/// The main window: kraft title bar, torn sidebar, and the current screen.
public struct RootView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            WindowTitleBar(model.windowTitle)
            ZStack(alignment: .topLeading) {
                content
                    .padding(.leading, Tokens.Metrics.sidebarWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Sidebar()
                    .frame(maxHeight: .infinity)
                    .zIndex(2)
            }
        }
        .background(Tokens.Palette.paper)
        .ignoresSafeArea()
        .frame(minWidth: 1100, minHeight: 720)
        .navigationTitle(model.windowTitle)
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK") { model.lastError = nil }
        } message: {
            Text(model.lastError ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch model.screen {
            case .map:
                WorldMapView()
            case .people, .moments, .notes, .settings:
                ComingNextView(screen: model.screen)
            }

            if let id = model.openMomentID, let moment = model.moment(id) {
                MomentPreview(moment: moment)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: model.openMomentID)
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { model.lastError != nil }, set: { if !$0 { model.lastError = nil } })
    }
}

/// Stand-in for screens that arrive in later iterations.
struct ComingNextView: View {
    let screen: Screen

    var body: some View {
        ZStack {
            DotGrid()
            VStack(spacing: Tokens.Space.ml) {
                Text(screen.number)
                    .textStyle(Tokens.Typography.monoSmall)
                    .foregroundStyle(screen.color.onFill)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: Tokens.Radius.chipSquare).fill(screen.color.fill))
                Text(screen.label)
                    .textStyle(Tokens.Typography.displayTitle)
                    .foregroundStyle(Tokens.Palette.ink)
                Text("this page gets built next. the world map is ready to explore.")
                    .textStyle(Tokens.Typography.handNote)
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-1.5))
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 56)
            .background(TornPaperShape().fill(Tokens.Palette.card))
            .shadow(Tokens.Shadows.paperCard)
            .rotationEffect(.degrees(-1))
        }
    }
}
