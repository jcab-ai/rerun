import RerunCore
import SwiftUI

/// 03 — "Who's in your world?": a polaroid strip for every conversation in
/// Messages, biggest first, tap to include. Search finds anyone by name,
/// group member or number.
struct ChoosePeopleView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""

    private static let tilts: [Double] = [-4, 3, -2, 5, -5, 2, -3]
    private static let drops: [CGFloat] = [0, 20, 0, 30, 10, 40, 14]

    /// Shows the sample world's people when there's nothing scanned (previews).
    private var candidates: [Person] {
        model.candidates.isEmpty ? DemoWorld.people : model.candidates
    }

    private var shown: [Person] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return candidates }
        let digits = trimmed.filter(\.isNumber)
        return candidates.filter { person in
            person.displayName.lowercased().contains(trimmed)
                || (person.fullName?.lowercased().contains(trimmed) ?? false)
                || person.members.contains { $0.lowercased().contains(trimmed) }
                || person.handles.contains { handle in
                    handle.lowercased().contains(trimmed) || (digits.count >= 3 && handle.filter(\.isNumber).contains(digits))
                }
        }
    }

    /// How many strips fit across before the row scrolls.
    private static let stripsAcross = 7

    private var chosen: [Person] { candidates.filter(\.included) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            VStack(spacing: 0) {
                header
                strips
                Spacer(minLength: 0)
                summaryBar
            }
            if let quiet = quietest {
                Text("\(quiet.displayName.lowercased()) mostly sends short ones — not much to work with yet ↓")
                    .textStyle(Tokens.TextStyle(.caveat(bold: false), 20, lineHeight: 1.05))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 230, alignment: .trailing)
                    .rotationEffect(.degrees(-4))
                    .place(right: 40, top: 192)
            }
        }
    }

    /// The smallest shown thread, if it's small enough to warn about.
    private var quietest: Person? {
        let visible = shown.prefix(Self.stripsAcross)
        guard query.isEmpty, let last = visible.last, visible.count > 3, last.messageCount < 1_000 else { return nil }
        return last
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                StepPips(step: 2)
                Text("Who's in your world?")
                    .textStyle(Tokens.Typography.displayTitle)
                    .foregroundStyle(Tokens.Palette.ink)
                Text("We found \(candidates.count) people you text a lot. Pick who gets stories — you can change this later.")
                    .textStyle(Tokens.TextStyle(.fredoka(.regular), 18))
                    .foregroundStyle(Tokens.Palette.inkSoft)
                    .frame(maxWidth: 560, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("⌕").foregroundStyle(Tokens.Palette.ink)
                AdaptiveTextField(placeholder: "add someone else…", text: $query, placeholderColor: Color(hex: 0x8C7E6A))
                    .foregroundStyle(Tokens.Palette.ink)
            }
            .font(Tokens.Typeface.fredoka(.regular).font(size: 15))
            .frame(width: 222, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.chip))
        }
        .padding(EdgeInsets(top: 40, leading: 56, bottom: 0, trailing: 56))
    }

    private var strips: some View {
        AdaptiveScroll(axes: .horizontal) {
            stripRow
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .bottomTrailing) {
            if shown.count > Self.stripsAcross {
                Text("\(shown.count - Self.stripsAcross) more conversations — scroll →")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 20))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-2))
                    .padding(.trailing, 48)
                    .allowsHitTesting(false)
            } else if shown.isEmpty {
                Text("no one by that name in Messages")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 22))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var stripRow: some View {
        HStack(alignment: .top, spacing: 26) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, person in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        model.setCandidate(person.id, included: !person.included)
                    }
                } label: {
                    VStack(spacing: 12) {
                        PolaroidStrip(person: person, caption: person.isGroup ? "\(person.displayName) 🦆" : person.displayName, check: person.included, showsTape: person.included)
                            .shadow(person.included
                                ? Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 22, y: 10)
                                : Tokens.Shadow(Tokens.Palette.ink.opacity(0.18), blur: 14, y: 6))
                        Text(countLabel(person))
                            .textStyle(Tokens.Typography.monoSmall)
                            .foregroundStyle(person.included ? Color.white : Tokens.Palette.ink)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(RoundedRectangle(cornerRadius: 6).fill(person.included ? Tokens.Palette.ink : Color.clear))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(person.included ? Color.clear : Tokens.Palette.ink, lineWidth: 1.5))
                    }
                    .saturation(person.included ? 1 : 0.3)
                    .opacity(person.included ? 1 : 0.55)
                    .rotationEffect(.degrees(Self.tilts[index % Self.tilts.count]))
                    .padding(.top, Self.drops[index % Self.drops.count])
                    .contentShape(Rectangle())
                }
                .buttonStyle(LiftOnHoverStyle())
                .help(person.included ? "Leave \(person.displayName) out" : "Include \(person.displayName)")
            }
        }
        .padding(EdgeInsets(top: 34, leading: 56, bottom: 30, trailing: 56))
    }

    private func countLabel(_ person: Person) -> String {
        let count = person.momentCount > 0 ? "\(person.momentCount) moments" : "\(person.messageCount.formatted()) texts"
        return person.isGroup ? "\(count) · group" : count
    }

    private var summaryBar: some View {
        let total = chosen.reduce(0) { $0 + ($1.momentCount > 0 ? $1.momentCount : $1.messageCount) }
        let unit = chosen.contains { $0.momentCount > 0 } ? "moments" : "texts"
        let since = chosen.compactMap(\.since).min().map { Calendar.current.component(.year, from: $0) }
        return HStack {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text("\(chosen.count) \(chosen.count == 1 ? "person" : "people")")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 24))
                    .foregroundStyle(Color.white)
                Text("\(total.formatted()) \(unit)" + (since.map { " · \($0) → today" } ?? ""))
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 13))
                    .foregroundStyle(Tokens.Palette.sun)
            }
            Spacer()
            if !model.isSampleWorld {
                Button("keep my world as is") { model.cancelChoosing() }
                    .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.fredoka(.medium), 16), color: .white))
                    .keyboardShortcut(.cancelAction)
                    .padding(.trailing, 14)
            }
            Button("Build my world →") { Task { await model.buildWorld() } }
                .buttonStyle(PillButtonStyle(fill: Tokens.Palette.sun, foreground: Tokens.Palette.ink, border: .white, text: Tokens.TextStyle(.fredoka(.semibold), 18), padding: EdgeInsets(top: 13, leading: 26, bottom: 13, trailing: 26)))
                .disabled(chosen.isEmpty)
                .keyboardShortcut(.defaultAction)
        }
        .padding(EdgeInsets(top: 16, leading: 26, bottom: 16, trailing: 20))
        .background(RoundedRectangle(cornerRadius: 16).fill(Tokens.Palette.ink))
        .rotationEffect(.degrees(-0.4))
        .padding(EdgeInsets(top: 0, leading: 40, bottom: 28, trailing: 40))
    }
}

/// A flat pill with a border and no hard shadow ("Build my world →", "continue →").
public struct PillButtonStyle: ButtonStyle {
    var fill: Color
    var foreground: Color
    var border: Color
    var text: Tokens.TextStyle
    var padding: EdgeInsets

    public init(fill: Color, foreground: Color, border: Color, text: Tokens.TextStyle, padding: EdgeInsets) {
        self.fill = fill
        self.foreground = foreground
        self.border = border
        self.text = text
        self.padding = padding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(text)
            .foregroundStyle(foreground)
            .padding(padding)
            .padding(Tokens.Stroke.button)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(border, lineWidth: Tokens.Stroke.button))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .contentShape(Capsule())
    }
}

/// Lifts and straightens a sticker a little on hover.
public struct LiftOnHoverStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Lifting(configuration: configuration)
    }

    private struct Lifting: View {
        let configuration: Configuration
        @State private var hovering = false

        var body: some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : (hovering ? 1.03 : 1))
                .offset(y: hovering ? -4 : 0)
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: hovering)
                .onHover { hovering = $0 }
        }
    }
}
