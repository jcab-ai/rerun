import RerunCore
import SwiftUI

/// 02 — what rerun reads, what it never does, and the Full Disk Access ask.
struct PrivacyView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            HStack(alignment: .top, spacing: 0) {
                pitch.frame(width: 540)
                stickers.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var pitch: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepPips(step: 1)
            // Three stacked lines rather than one wrapping Text so "Right here,"
            // can carry its highlighter swipe; the negative spacing gets
            // Fredoka's tall natural line box down to the mockup's 1.02.
            VStack(alignment: .leading, spacing: -8) {
                Text("rerun reads your")
                HStack(spacing: 10) {
                    Text("Messages.")
                    Text("Right here,")
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Tokens.Palette.sun).padding(.vertical, 6))
                        .rotationEffect(.degrees(-1.5))
                    Text("on")
                }
                Text("this Mac.")
            }
            .lineLimit(1)
            .fixedSize()
            .textStyle(Tokens.Typography.headline)
            .foregroundStyle(Tokens.Palette.ink)

            Text("To build your world, rerun looks through your message history to find the moments that mattered — trips, fights, inside jokes — and learns how each person texts. It all happens on your computer. Nobody else sees it, including us.")
                .textStyle(Tokens.Typography.bodyCompact)
                .foregroundStyle(Tokens.Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button("Allow access to Messages") { model.requestMessagesAccess() }
                    .buttonStyle(HardShadowButtonStyle(
                        fill: Tokens.Palette.blue,
                        text: Tokens.TextStyle(.fredoka(.semibold), 19),
                        padding: EdgeInsets(top: 15, leading: 28, bottom: 15, trailing: 28)
                    ))
                    .keyboardShortcut(.defaultAction)
                Button("not now") { model.skipOnboarding() }
                    .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.medium), 18)))
                    .padding(.horizontal, 18)
                    .help("Explore the sample world first. You can scan Messages any time from Settings.")
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            (Text("macOS will ask you to turn on ") + Text("Full Disk Access").fontWeight(.bold)
                + Text(" — it's the only way any app can open the Messages library. You can switch it off anytime in System Settings → Privacy & Security."))
                .textStyle(Tokens.TextStyle(.mono(bold: false), 11.5, lineHeight: 1.6))
                .foregroundStyle(Tokens.Palette.pencilDark)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .dashedBox()
        }
        .padding(EdgeInsets(top: 48, leading: 56, bottom: 36, trailing: 36))
    }

    private var stickers: some View {
        ZStack {
            PanelSticker(Tokens.Palette.leaf, width: 310) {
                Text("WHAT WE READ").textStyle(Tokens.Typography.monoSmall.withTracking(1.5))
                bullets(["the text of your messages", "who you talk to, and when", "photo & file names (not the photos)", "how people type — caps, emoji, timing"])
            }
            .rotationEffect(.degrees(-4))
            .place(left: 30, top: 56)
            Tape(width: 84, height: 24, angle: 6).place(left: 150, top: 44)

            PanelSticker(Tokens.Palette.coral, width: 320) {
                Text("WHAT WE NEVER DO").textStyle(Tokens.Typography.monoSmall.withTracking(1.5))
                bullets(["send a text to anyone. ever.", "upload your messages anywhere", "show your contacts they're in it", "sell, share, or train on any of it"])
            }
            .rotationEffect(.degrees(3))
            .place(left: 300, top: 200)

            ReceiptPaper(width: 290, fontSize: 12, lineHeight: 1.75, padding: EdgeInsets(top: 20, leading: 22, bottom: 34, trailing: 22), teeth: 8) {
                Text("PRIVACY RECEIPT").fontWeight(.bold).tracking(2).frame(maxWidth: .infinity)
                Text("rerun · \(machineName)")
                    .font(Tokens.Typeface.mono(bold: false).font(size: 10))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                DashedRule().padding(.vertical, 8)
                row("messages read", "local")
                row("stories written", "local")
                row("texts sent", "0")
                row("bytes uploaded", "0")
                DashedRule().padding(.vertical, 8)
                row("YOU OWE", "NOTHING").fontWeight(.bold)
            }
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 18, y: 10))
            .rotationEffect(.degrees(-2))
            .place(left: 60, top: 400)

            PanelSticker(Tokens.Palette.grape, width: 250, padding: 22) {
                Text("YOU'RE IN CHARGE").textStyle(Tokens.Typography.monoSmall.withTracking(1.5))
                Text("Pick exactly who's included. Erase your whole world with one button.")
                    .textStyle(Tokens.TextStyle(.fredoka(.regular), 17, lineHeight: 1.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .rotationEffect(.degrees(-5))
            .place(left: 390, top: 440)

            Text("read this bit ↓")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 26))
                .foregroundStyle(Tokens.Palette.ink)
                .rotationEffect(.degrees(8))
                .place(left: 470, top: 84)

            Postmark(top: "RERUN", middle: "LOCAL", bottom: "ONLY", color: Tokens.Palette.leaf)
                .rotationEffect(.degrees(-14))
                .place(left: 220, top: 640)
        }
        .foregroundStyle(Color.white)
    }

    private func bullets(_ lines: [String]) -> some View {
        Text(lines.map { "• \($0)" }.joined(separator: "\n"))
            .textStyle(Tokens.TextStyle(.fredoka(.regular), 17, lineHeight: 1.5))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }

    /// "Jules's MacBook Pro" when the Mac has a proper name; build machines
    /// and bare hostnames get "this Mac (Jules)" instead.
    private var machineName: String {
        if let name = Host.current().localizedName, name.contains(" ") { return name }
        return "this Mac (\(model.player.name))"
    }
}
