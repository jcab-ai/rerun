import AppKit
import RerunCore
import SwiftUI

/// 09 — the story plays out on a kraft-paper table: the chapter card, your
/// lock screen, a simulated iPhone thread, and three ways to text back.
/// Nothing here is ever sent to anyone.
struct PlayView: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject var session: PlaySession

    private var lead: Person? { session.lead }
    private var leadName: String { lead?.displayName ?? "them" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KraftPaper(period: 6)
            topBar
            chapterCard
                .rotationEffect(.degrees(-3))
                .place(left: 40, top: 84)
            LockScreenPolaroid(session: session)
                .rotationEffect(.degrees(4))
                .place(left: 66, top: 380)
            PhoneFrame(session: session)
                .rotationEffect(.degrees(-1.5))
                .frame(maxWidth: .infinity)
                .padding(.top, 66)
                .offset(x: -8)
                .zIndex(2)
            evidenceSticker
                .place(right: 46, top: 96)
            VoiceMatchCard(session: session)
                .rotationEffect(.degrees(-2))
                .place(right: 60, top: 270)
            Text("simulated — nothing is sent to the real \(leadName)")
                .textStyle(Tokens.TextStyle(.caveat(bold: false), 20, lineHeight: 1.15))
                .foregroundStyle(Tokens.Palette.ink)
                .frame(width: 200, alignment: .leading)
                .rotationEffect(.degrees(4))
                .place(right: 70, top: 470)
            Doodle.whoosh.frame(width: 34, height: 22).foregroundStyle(Tokens.Palette.ink.opacity(0.5)).rotationEffect(.degrees(-20)).place(right: 300, top: 455)
            bottom
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 26)
                .zIndex(3)
            if case .failed(let failure) = session.phase {
                failureCard(failure)
                    .zIndex(4)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.phase)
        .background(choiceShortcuts)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 16) {
            Button("← world map") { model.stopPlaying() }
                .buttonStyle(PillButtonStyle(fill: Tokens.Palette.card, foreground: Tokens.Palette.ink, border: Tokens.Palette.ink, text: Tokens.TextStyle(.fredoka(.semibold), 15), padding: EdgeInsets(top: 4, leading: 11, bottom: 4, trailing: 11)))
                .keyboardShortcut(.cancelAction)
            Text(session.moment.title)
                .font(Tokens.Typeface.fredoka(.bold).font(size: 20))
                .foregroundStyle(Tokens.Palette.ink)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...max(1, session.run.chapterCount), id: \.self) { chapter in
                    Capsule()
                        .fill(chapter <= chapterShown ? Tokens.Palette.coral : Tokens.Palette.pipOff)
                        .frame(width: 26, height: 8)
                }
                Text("CH \(chapterShown) / \(session.run.chapterCount)")
                    .textStyle(Tokens.Typography.monoSmall)
                    .foregroundStyle(Tokens.Palette.ink)
                    .padding(.leading, 6)
            }
        }
        .padding(.horizontal, 28)
        .frame(height: 56)
    }

    private var chapterShown: Int { session.sceneBeat?.chapter ?? 1 }

    // MARK: Chapter card

    private var chapterCard: some View {
        let beat = session.sceneBeat
        let ended = session.phase == .ended
        let chapters = beat?.chapter ?? session.run.chapterCount
        return VStack(alignment: .leading, spacing: 10) {
            Text(ended
                 ? "THE END · \(chapters) CHAPTER\(chapters == 1 ? "" : "S") LATER"
                 : "CHAPTER \(beat?.chapter ?? 1)" + (beat?.chapterTitle.map { " · \($0.uppercased())" } ?? ""))
                .textStyle(Tokens.TextStyle(.mono(bold: false), 10, tracking: 1.5))
                .lineLimit(2)
            if let beat {
                Text(beat.narration)
                    .textStyle(Tokens.TextStyle(.fredoka(.semibold), 19, lineHeight: 1.35))
                    .fixedSize(horizontal: false, vertical: true)
                if let aside = beat.aside {
                    Text(aside)
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 20))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("setting the scene…")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 24))
                    .padding(.vertical, 20)
            }
        }
        .foregroundStyle(Tokens.Palette.ink)
        .padding(22)
        .frame(width: 290, alignment: .leading)
        .sticker(Tokens.Palette.sun, borderWidth: Tokens.Stroke.panel, radius: Tokens.Radius.panel)
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 22, y: 10))
        .id(beat?.chapter ?? 0)
        .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
    }

    // MARK: Evidence

    @ViewBuilder
    private var evidenceSticker: some View {
        if let evidence = session.moment.evidence {
            switch evidence.kind {
            case .boardingPass:
                MiniBoardingPass(evidence: evidence).rotationEffect(.degrees(6))
            case .receipt:
                ReceiptProp(evidence: evidence, moment: session.moment, width: 200).scaleEffect(0.8).rotationEffect(.degrees(6)).offset(x: 20, y: -30)
            case .ticketStub:
                TicketStubProp(evidence: evidence, moment: session.moment, color: lead?.color ?? .sun, width: 260).rotationEffect(.degrees(6))
            case .voiceMemo:
                VoiceMemoProp(evidence: evidence, moment: session.moment, person: lead).scaleEffect(0.85).rotationEffect(.degrees(5))
            case .polaroid:
                PolaroidPhoto(caption: evidence[.caption] ?? session.moment.title.lowercased(), color: lead?.color ?? .coral, size: 150).rotationEffect(.degrees(6))
            }
        } else if let caption = session.moment.photoCaption {
            PolaroidPhoto(caption: caption, color: lead?.color ?? .coral, size: 150).rotationEffect(.degrees(6))
        }
    }

    // MARK: Choices & the chapter bar

    @ViewBuilder
    private var bottom: some View {
        switch session.phase {
        case .choosing:
            if let beat = session.current {
                VStack(spacing: 12) {
                    Text(prompt(for: beat))
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 24))
                        .foregroundStyle(Tokens.Palette.ink)
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(Array(beat.choices.enumerated()), id: \.offset) { index, choice in
                            Button { session.pick(index) } label: {
                                Text(choice.text)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 250 - 36 - 6, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .buttonStyle(HardShadowButtonStyle.choice(Self.choiceColors[index % 3], tilt: Tokens.Tilt.choices[index % 3]))
                            .help("Pick \(index + 1)")
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        case .waiting, .loading:
            ChapterBar {
                HStack(spacing: 8) {
                    Text("\(leadName) is typing")
                        .font(Tokens.Typeface.fredoka(.bold).font(size: 20))
                        .foregroundStyle(Color.white)
                    TypingDots(color: Tokens.Palette.sun)
                }
                if session.phase == .waiting {
                    Button("pick again") { session.pickAgain() }
                        .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.regular), 15), color: .white))
                }
            }
        case .revealed:
            if let next = session.pending {
                ChapterBar {
                    Text(next.endsStory ? "The end" : "Chapter \(next.chapter) unlocked")
                        .font(Tokens.Typeface.fredoka(.bold).font(size: 20))
                        .foregroundStyle(Color.white)
                    Text(next.endsStory ? (next.outcome ?? "") : (next.chapterTitle ?? ""))
                        .textStyle(Tokens.TextStyle(.mono(bold: false), 12))
                        .foregroundStyle(Tokens.Palette.sun)
                        .lineLimit(1)
                    Button(next.endsStory ? "see how it ends →" : "continue →") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { session.continueStory() }
                    }
                    .buttonStyle(PillButtonStyle(fill: Tokens.Palette.sun, foreground: Tokens.Palette.ink, border: .white, text: Tokens.TextStyle(.fredoka(.semibold), 16), padding: EdgeInsets(top: 7, leading: 19, bottom: 7, trailing: 19)))
                    .keyboardShortcut(.defaultAction)
                    Button("pick again") { session.pickAgain() }
                        .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.regular), 15), color: .white))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        case .ended:
            ChapterBar {
                Text("The end")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 20))
                    .foregroundStyle(Color.white)
                Text(session.run.outcome ?? "")
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 12))
                    .foregroundStyle(Tokens.Palette.sun)
                Button("play again") { model.play(session.moment) }
                    .buttonStyle(PillButtonStyle(fill: Tokens.Palette.sun, foreground: Tokens.Palette.ink, border: .white, text: Tokens.TextStyle(.fredoka(.semibold), 16), padding: EdgeInsets(top: 7, leading: 19, bottom: 7, trailing: 19)))
                Button("back to world map") { model.stopPlaying() }
                    .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.regular), 15), color: .white))
                    .keyboardShortcut(.defaultAction)
            }
            .overlay(alignment: .topTrailing) {
                Text("saved to your world ✓")
                    .font(Tokens.Typeface.caveat(bold: true).font(size: 17))
                    .foregroundStyle(Tokens.Palette.ink)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 9)
                    .background(Capsule().fill(Tokens.Palette.leaf.opacity(0.9)))
                    .rotationEffect(.degrees(8))
                    .offset(x: 30, y: -22)
            }
        case .failed:
            EmptyView()
        }
    }

    private static let choiceColors = [Tokens.Palette.leaf, Tokens.Palette.coral, Tokens.Palette.grape]

    private func prompt(for beat: StoryBeat) -> String {
        beat.choices.allSatisfy { $0.sentText != nil } || beat.choices.first?.sentText != nil ? "what do you text back?" : "what do you do?"
    }

    /// 1, 2, 3 pick a choice.
    private var choiceShortcuts: some View {
        ZStack {
            if session.phase == .choosing, let beat = session.current {
                ForEach(Array(beat.choices.indices), id: \.self) { index in
                    Button("") { session.pick(index) }
                        .keyboardShortcut(KeyEquivalent(Character(String(index + 1))), modifiers: [])
                }
            }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
    }

    // MARK: Failures

    @ViewBuilder
    private func failureCard(_ failure: PlaySession.Failure) -> some View {
        ZStack {
            Color.black.opacity(0.18)
            Group {
                switch failure {
                case .lostInTheMail(let detail):
                    EmptyStateCard(
                        title: "This chapter got lost in the mail",
                        message: "We couldn't finish writing chapter \(session.run.currentChapter) of “\(session.moment.title).” Your progress is saved. Try again, or switch to the on-device model if your connection's spotty.",
                        primary: "Try again",
                        primaryFill: Tokens.Palette.coral,
                        primaryInk: .white,
                        primaryAction: session.retry,
                        secondary: model.onDeviceAvailable ? "use on-device model" : "back to world map",
                        secondaryAction: fallback
                    ) { EnvelopeArt() }
                    .help(detail)
                case .noStoryteller:
                    EmptyStateCard(
                        title: "No storyteller yet",
                        message: "This moment needs a story model. Add an API key in Settings — or, on macOS 26 with Apple Intelligence, let the model on this Mac write it. Nothing is ever sent to \(leadName).",
                        primary: "Add an API key",
                        primaryFill: Tokens.Palette.blue,
                        primaryInk: .white,
                        primaryAction: Self.openSettingsWindow,
                        secondary: model.onDeviceAvailable ? "use on-device model" : "back to world map",
                        secondaryAction: fallback
                    ) { ChatBubbleArt() }
                case .onDeviceUnavailable:
                    EmptyStateCard(
                        title: "The model on this Mac is asleep",
                        message: "Writing on-device \(OnDeviceModel.unavailableReason). You can switch this moment to a cloud model with your own API key.",
                        primary: "Use cloud model",
                        primaryFill: Tokens.Palette.sun,
                        primaryInk: Tokens.Palette.ink,
                        primaryAction: { model.updateSettings { $0.storyModel = .cloud }; model.play(session.moment) },
                        secondary: "back to world map",
                        secondaryAction: { model.stopPlaying() }
                    ) { PadlockArt() }
                }
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 60)
            .background(TornPaperShape(depth: 0.02).fill(Tokens.Palette.paper))
            .shadow(Tokens.Shadows.paperCard)
            .rotationEffect(.degrees(-1))
        }
    }

    /// Switch to the on-device model when there is one, otherwise leave.
    private func fallback() {
        if model.onDeviceAvailable {
            model.useOnDeviceModel()
            model.play(session.moment)
        } else {
            model.stopPlaying()
        }
    }

    static func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

/// The dark bar that replaces the choices after you pick.
struct ChapterBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 16) { content }
            .padding(EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 16))
            .background(RoundedRectangle(cornerRadius: 18).fill(Tokens.Palette.ink))
            .rotationEffect(.degrees(-0.5))
            .fixedSize()
    }
}

/// Three dots pulsing in turn.
struct TypingDots: View {
    var color: Color = Tokens.Palette.Messages.meta
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: isRenderingSnapshot)) { timeline in
            let t = isRenderingSnapshot ? 0 : timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 7, height: 7)
                        .opacity(0.35 + 0.65 * max(0, sin((t * 4) - Double(index) * 0.8)))
                }
            }
        }
    }
}
