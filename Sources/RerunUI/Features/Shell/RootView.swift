import RerunCore
import SwiftUI

/// The main window: kraft title bar, then onboarding, the play table, or the
/// torn sidebar with the current screen.
public struct RootView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            WindowTitleBar(model.windowTitle, background: model.onboarding == nil ? Tokens.Palette.kraft : Tokens.Palette.kraftLight)
            ZStack {
                if let step = model.onboarding {
                    onboarding(step)
                        .transition(.opacity)
                } else if let session = model.playSession {
                    PlayView(session: session)
                        .id(session.id)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                } else {
                    main.transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: model.onboarding)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.playSession?.id)
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
    private func onboarding(_ step: OnboardingStep) -> some View {
        switch step {
        case .welcome: WelcomeView()
        case .privacy: PrivacyView()
        case .choosePeople: ChoosePeopleView()
        case .building: BuildingWorldView()
        case .locked, .noConversations: OnboardingProblemView(step: step)
        }
    }

    private var main: some View {
        ZStack(alignment: .topLeading) {
            content
                .padding(.leading, Tokens.Metrics.sidebarWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Sidebar()
                .frame(maxHeight: .infinity)
                .zIndex(2)
        }
    }

    private var content: some View {
        ZStack {
            Group {
                switch model.screen {
                case .map: WorldMapView()
                case .people: PeopleView()
                case .moments: MomentsView()
                case .notes: ContextNotesView()
                case .settings: ContentsView()
                }
            }
            .id(model.screen)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 8)), removal: .opacity))

            if let id = model.openMomentID, let moment = model.moment(id) {
                MomentDetailView(moment: moment)
                    .id(moment.id)
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .animation(.easeOut(duration: 0.18), value: model.openMomentID)
        .animation(.easeOut(duration: 0.2), value: model.screen)
        .clipped()
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { model.lastError != nil }, set: { if !$0 { model.lastError = nil } })
    }
}
