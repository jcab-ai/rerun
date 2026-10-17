import RerunCore
import SwiftUI

/// A white-framed photo of an iPhone, taped down, showing the simulated thread.
struct PhoneFrame: View {
    @ObservedObject var session: PlaySession

    var body: some View {
        PhoneScreen(session: session)
            .frame(width: 284, height: 458)
            .background(RoundedRectangle(cornerRadius: 27).fill(Color.white))
            .clipShape(RoundedRectangle(cornerRadius: 27))
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 34).fill(Color.black))
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 14, trailing: 12))
            .background(Color.white)
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.3), blur: 32, y: 16))
            .overlay(alignment: .top) {
                Tape(Color(.sRGB, red: 255 / 255, green: 236 / 255, blue: 170 / 255, opacity: 0.88), width: 100, height: 26, angle: 3)
                    .offset(y: -12)
            }
    }
}

/// The inside of the phone: status bar, contact header, bubbles, input field.
struct PhoneScreen: View {
    @ObservedObject var session: PlaySession

    private var lead: Person? { session.lead }
    private var isGroup: Bool { lead?.isGroup == true }

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            header
            thread
            inputBar
        }
        .font(.system(size: 13))
    }

    private var statusBar: some View {
        ZStack {
            HStack {
                Text(session.current?.clock ?? DateFormatter.rerun("h:mm").string(from: session.moment.date))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("5G ▮ 82%").font(.system(size: 11))
            }
            Capsule().fill(Color.black).frame(width: 84, height: 22)
        }
        .foregroundStyle(Color.black)
        .padding(.horizontal, 20)
        .frame(height: 32)
    }

    private var header: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(LinearGradient(colors: avatarColors, startPoint: .top, endPoint: .bottom))
                Text(isGroup ? "🦆" : (lead?.initial ?? "?"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 40, height: 40)
            Text("\(lead?.displayName ?? "them") ›").font(.system(size: 11)).foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(Tokens.Palette.Messages.header)
        .overlay(alignment: .topLeading) {
            Text("‹").font(.system(size: 22)).foregroundStyle(Tokens.Palette.Messages.bubbleMe).padding(.leading, 12).padding(.top, 6)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Tokens.Palette.Messages.separator).frame(height: 0.5) }
    }

    private var avatarColors: [Color] {
        let shades = (lead?.color ?? .coral).shades
        return [shades[1], shades[0]]
    }

    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    @ViewBuilder
    private var thread: some View {
        if isRenderingSnapshot {
            ScrollStandIn(axes: .vertical, anchor: .bottom) { messages }
                .clipped()
        } else {
            scrollingThread
        }
    }

    private var messages: some View {
        VStack(spacing: 3) {
            ForEach(Array(session.phoneItems.enumerated()), id: \.offset) { index, item in
                row(item, previous: index > 0 ? session.phoneItems[index - 1] : nil)
                    .id(index)
                    .transition(.asymmetric(insertion: .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity), removal: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var scrollingThread: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                messages.frame(minHeight: 330, alignment: .bottom)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: session.phoneItems.count) { _, count in
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(count - 1, anchor: .bottom) }
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: session.phoneItems.count)
    }

    @ViewBuilder
    private func row(_ item: PlaySession.PhoneItem, previous: PlaySession.PhoneItem?) -> some View {
        switch item {
        case .time(let text):
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(Tokens.Palette.Messages.meta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        case .receipt(let text):
            Text(text)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Tokens.Palette.Messages.meta)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
        case .typing:
            TypingDots()
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 17).fill(Tokens.Palette.Messages.bubbleThem))
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bubble(let message):
            bubble(message, showsName: showsName(message, previous: previous))
        }
    }

    /// Group threads label each run of messages with the sender's name.
    private func showsName(_ message: SimulatedMessage, previous: PlaySession.PhoneItem?) -> Bool {
        guard isGroup, !message.isFromPlayer else { return false }
        if case .bubble(let last) = previous { return last.senderID != message.senderID }
        return true
    }

    private func bubble(_ message: SimulatedMessage, showsName: Bool) -> some View {
        let mine = message.isFromPlayer
        return VStack(alignment: mine ? .trailing : .leading, spacing: 1) {
            if showsName {
                Text(name(for: message.senderID))
                    .font(.system(size: 9))
                    .foregroundStyle(Tokens.Palette.Messages.meta)
                    .padding(.leading, 11)
            }
            Text(message.text)
                .font(.system(size: 13.5))
                .lineSpacing(2)
                .foregroundStyle(mine ? Color.white : Color.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 11)
                .background(RoundedRectangle(cornerRadius: 17).fill(mine ? Tokens.Palette.Messages.bubbleMe : Tokens.Palette.Messages.bubbleThem))
                .frame(maxWidth: 200, alignment: mine ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private func name(for id: String?) -> String {
        guard let id else { return "you" }
        return session.person(id)?.displayName ?? id.capitalized
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("+")
                .font(.system(size: 18))
                .foregroundStyle(Tokens.Palette.Messages.meta)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Tokens.Palette.Messages.bubbleThem))
            Text("iMessage")
                .font(.system(size: 13))
                .foregroundStyle(Tokens.Palette.Messages.placeholder)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .overlay(Capsule().strokeBorder(Tokens.Palette.Messages.fieldBorder, lineWidth: 1))
        }
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 12, trailing: 10))
    }
}

/// A polaroid of your lock screen with the latest notification.
struct LockScreenPolaroid: View {
    @ObservedObject var session: PlaySession

    private var latest: SimulatedMessage? {
        session.current?.messages.first { !$0.isFromPlayer } ?? session.current?.reactions.first { !$0.isFromPlayer }
    }

    private var clock: String {
        session.current?.clock ?? DateFormatter.rerun("h:mm").string(from: session.moment.date)
    }

    var body: some View {
        let lead = session.lead
        let others = max(0, (session.current?.messages.filter { !$0.isFromPlayer }.count ?? 0) - 1)
        VStack(spacing: 2) {
            Text(DateFormatter.rerun("EEEE, MMMM d").string(from: session.moment.date))
                .font(.system(size: 12, weight: .semibold))
                .opacity(0.9)
            Text(clock)
                .font(.system(size: 60, weight: .bold))
                .tracking(-2)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let latest {
                HStack(alignment: .top, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Tokens.Palette.leaf).frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(session.person(latest.senderID)?.displayName ?? lead?.displayName ?? "").bold()
                            Spacer()
                            Text("now").opacity(0.6)
                        }
                        Text(latest.text).lineLimit(2)
                    }
                    .font(.system(size: 11))
                }
                .foregroundStyle(Tokens.Palette.ink)
                .padding(.vertical, 9)
                .padding(.horizontal, 10)
                .frame(width: 196)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.72)))
                .padding(.top, 18)
                if others > 0 {
                    Text("\(others) more from \(lead?.displayName ?? "them")")
                        .font(.system(size: 10))
                        .foregroundStyle(Tokens.Palette.ink)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .frame(width: 184, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.5)))
                        .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.white)
        .padding(.top, 20)
        .frame(width: 220, height: 230)
        .background(
            LinearGradient(stops: [
                .init(color: Tokens.Palette.blue, location: 0),
                .init(color: Tokens.Palette.grape, location: 0.7),
                .init(color: Tokens.Palette.coral, location: 1),
            ], startPoint: UnitPoint(x: 0.4, y: 0), endPoint: UnitPoint(x: 0.6, y: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 36, trailing: 10))
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Text("your lock screen, \(clock)")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                .foregroundStyle(Tokens.Palette.ink)
                .padding(.bottom, 6)
        }
        .overlay(alignment: .topLeading) {
            Tape(Tokens.Palette.tapeBlue, width: 80, height: 22, angle: -5).offset(x: 70, y: -11)
        }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 22, y: 10))
    }
}

/// "MAYA'S VOICE MATCH · 94% sounds like maya".
struct VoiceMatchCard: View {
    @ObservedObject var session: PlaySession

    var body: some View {
        let lead = session.lead
        let match = session.voiceMatch
        let color = lead?.color.fill ?? Tokens.Palette.coral
        VStack(alignment: .leading, spacing: 10) {
            Text("\((lead?.displayName ?? "their").uppercased())'S VOICE MATCH")
                .textStyle(Tokens.Typography.monoEyebrow)
                .foregroundStyle(Tokens.Palette.pencil)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(match.map { "\($0.percent)%" } ?? "—")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 40))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                Text(match == nil ? "still listening…" : "sounds like \(lead?.displayName.lowercased() ?? "them")")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                    .foregroundStyle(Tokens.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Tokens.Palette.ink.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geometry.size.width * (match?.score ?? 0))
                }
            }
            .frame(height: 8)
            .animation(.easeOut(duration: 0.6), value: match?.score)
            if let match, !match.checks.isEmpty {
                Text(checkLines(match))
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 10, lineHeight: 1.6))
                    .foregroundStyle(Tokens.Palette.inkSoft)
            }
        }
        .padding(18)
        .frame(width: 230, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Tokens.Palette.card))
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.18), blur: 18, y: 8))
    }

    /// "lowercase ✓ bursts ✓\ncaps for panic ✓"
    private func checkLines(_ match: VoiceMatch) -> String {
        let marks = match.checks.map { "\($0.label) \($0.passed ? "✓" : "✗")" }
        return stride(from: 0, to: marks.count, by: 2).map { marks[$0..<min($0 + 2, marks.count)].joined(separator: " ") }.joined(separator: "\n")
    }
}
