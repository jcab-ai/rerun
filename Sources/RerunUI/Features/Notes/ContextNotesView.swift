import RerunCore
import SwiftUI

/// 07 — "Tell rerun what the texts don't": a lined notepad of private notes
/// about one person, pinned to them or to specific moments.
struct ContextNotesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var draft = ""
    @State private var pinToPerson = true
    @State private var pinnedMoments: Set<String> = []
    @State private var promptIndex = 0
    @FocusState private var editing: Bool

    private var person: Person? {
        model.notesPersonID.flatMap(model.person) ?? model.includedPeople.first
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DotGrid()
            if let person {
                HStack(alignment: .top, spacing: 40) {
                    sidebar(person).frame(width: 270)
                    editor(person)
                }
                .padding(EdgeInsets(top: 36, leading: 44, bottom: 32, trailing: 40))
                .id(person.id)
            } else {
                Text("no one to write about yet.")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 26))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: resetPins)
        .onChange(of: model.notesPersonID) { _, _ in resetPins() }
        .onChange(of: model.notesMomentID) { _, _ in resetPins() }
    }

    private func resetPins() {
        draft = ""
        if let moment = model.notesMomentID {
            pinnedMoments = [moment]
            pinToPerson = model.notesPersonID != nil
        } else {
            pinnedMoments = []
            pinToPerson = true
        }
    }

    // MARK: Left column

    private func sidebar(_ person: Person) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(spacing: 0) {
                Text(person.isGroup ? "🦆" : person.initial)
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 80))
                    .foregroundStyle(person.color.onFill)
                    .frame(width: 220, height: 190)
                    .background(person.color.fill)
                Text(person.captionName)
                    .font(Tokens.Typeface.caveat(bold: true).font(size: 26))
                    .foregroundStyle(Tokens.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 220, height: 44)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .background(Color.white)
            .overlay(alignment: .topLeading) { Tape(width: 90, height: 24, angle: 4).offset(x: 70, y: -12) }
            .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.22), blur: 22, y: 10))
            .rotationEffect(.degrees(-4))

            if let lines = model.voice(person.id)?.learnedLines, !lines.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("WHAT THE TEXTS TAUGHT US").textStyle(Tokens.Typography.monoEyebrow)
                    Text(lines.joined(separator: "\n"))
                        .textStyle(Tokens.TextStyle(.fredoka(.regular), 15, lineHeight: 1.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(person.color.onFill)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sticker(person.color.fill, borderWidth: Tokens.Stroke.sticker, radius: Tokens.Radius.choice)
                .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 18, y: 8))
                .rotationEffect(.degrees(1.5))
            }

            Text("the texts only tell half of it. you know the rest →")
                .textStyle(Tokens.TextStyle(.caveat(bold: false), 20, lineHeight: 1.2))
                .foregroundStyle(Tokens.Palette.pencil)
                .rotationEffect(.degrees(-1))

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES FOR").textStyle(Tokens.Typography.monoEyebrow).foregroundStyle(Tokens.Palette.pencil)
                HStack(spacing: 6) {
                    ForEach(model.includedPeople) { other in
                        Button {
                            model.notesPersonID = other.id
                            model.notesMomentID = nil
                        } label: {
                            Text(other.isGroup ? "🦆" : other.initial)
                                .font(Tokens.Typeface.fredoka(.bold).font(size: 12))
                                .foregroundStyle(other.color.onFill)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(other.color.fill))
                                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                                .background(Circle().fill(other.id == person.id ? Tokens.Palette.ink : .clear).padding(-3))
                                .shadow(Tokens.Shadows.avatar)
                        }
                        .buttonStyle(LiftOnHoverStyle())
                        .help(other.displayName)
                    }
                }
            }
        }
    }

    // MARK: Notepad

    private func editor(_ person: Person) -> some View {
        let notes = model.notes(aboutPerson: person.id)
        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tell rerun what the texts don't.")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: 40))
                    .tracking(-1)
                    .foregroundStyle(Tokens.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Private notes. They shape how \(person.displayName) acts in stories — they're never shown to \(person.displayName) or quoted back.")
                    .textStyle(Tokens.TextStyle(.fredoka(.regular), 17))
                    .foregroundStyle(Tokens.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ZStack(alignment: .topTrailing) {
                notepad(notes, person)
                    .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 20, y: 10))
                promptNote(person)
                    .offset(x: 14, y: -26)
            }

            pinRow(person)
        }
    }

    private static let lineHeight: CGFloat = 34
    private static let paperTop: CGFloat = 58

    private func notepad(_ notes: [ContextNote], _ person: Person) -> some View {
        AdaptiveScroll {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(notes) { note in
                    NoteParagraph(note: note, tag: tag(for: note, person)) { model.deleteNote(note) }
                }
                AdaptiveTextField(placeholder: notes.isEmpty ? "start writing…" : "and another thing…", text: $draft, axis: .vertical, placeholderColor: Tokens.Palette.pencil.opacity(0.6))
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 25))
                    .lineSpacing(Self.handwritingSpacing)
                    .foregroundStyle(Tokens.Palette.ink)
                    .focused($editing)
                    .frame(minHeight: Self.lineHeight * 3, alignment: .topLeading)
            }
            .padding(EdgeInsets(top: Self.paperTop - 1, leading: 78, bottom: 30, trailing: 28))
            .frame(maxWidth: .infinity, alignment: .leading)
            // The mockup's rules start 18 + 33pt down; Caveat's baseline sits just above each one.
            .background(alignment: .top) { RuledLines(top: 51, spacing: Self.lineHeight) }
        }
        .background(Tokens.Palette.card)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color(hex: 0xFF9A82)).frame(width: 2).padding(.leading, 58)
        }
        .clipShape(NotepadShape())
        .contentShape(Rectangle())
        .onTapGesture { editing = true }
    }

    /// Extra leading so Caveat lands on the ruled lines.
    static var handwritingSpacing: CGFloat {
        Tokens.TextStyle(.caveat(bold: false), 25, lineHeight: lineHeight / 25).lineSpacing
    }

    private func promptNote(_ person: Person) -> some View {
        let prompts = Self.prompts(for: person, voice: model.voice(person.id))
        return Button {
            promptIndex += 1
            if draft.isEmpty { editing = true }
        } label: {
            Text(prompts[promptIndex % prompts.count])
                .textStyle(Tokens.TextStyle(.caveat(bold: false), 19, lineHeight: 1.15))
                .foregroundStyle(Tokens.Palette.ink)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(width: 190, alignment: .leading)
                .background(Tokens.Palette.sun)
                .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.2), blur: 14, y: 6))
                .rotationEffect(.degrees(5))
        }
        .buttonStyle(.plain)
        .help("another idea")
    }

    static func prompts(for person: Person, voice: VoiceProfile?) -> [String] {
        var prompts: [String] = []
        if voice?.terminalPeriodRate ?? 0 > 0.6 { prompts.append("try: what does “Ok.” mean from \(person.displayName)?") }
        if let laugh = voice?.laughs.first { prompts.append("try: when is “\(laugh)” not actually a laugh?") }
        if voice?.shoutRate ?? 0 > 0.08 { prompts.append("try: what makes \(person.displayName) go ALL CAPS?") }
        prompts += [
            "try: what never makes it into the texts?",
            "try: the inside joke nobody else gets",
            "try: what's off-limits, even in a story?",
            "try: how \(person.displayName) acts in person vs. in texts",
        ]
        return prompts
    }

    private func tag(for note: ContextNote, _ person: Person) -> String {
        switch note.subject {
        case .person: "all of \(person.displayName)"
        case .moment(let id): model.moment(id)?.title ?? "a moment"
        }
    }

    // MARK: Pinning

    private func pinRow(_ person: Person) -> some View {
        let moments = model.moments(with: person.id)
        return HStack(spacing: 8) {
            Text("PIN TO").textStyle(Tokens.Typography.monoEyebrow).foregroundStyle(Tokens.Palette.pencil).fixedSize()
            Button { pinToPerson.toggle() } label: {
                pinChip("all of \(person.displayName)", fill: pinToPerson ? person.color.fill : .clear, ink: pinToPerson ? person.color.onFill : Tokens.Palette.ink, dashed: !pinToPerson)
            }
            .buttonStyle(.plain)
            AdaptiveScroll(axes: .horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moments.filter { pinnedMoments.contains($0.id) }) { moment in
                        Button { pinnedMoments.remove(moment.id) } label: {
                            pinChip("✓ \(moment.title)", fill: Tokens.Palette.ink, ink: .white, dashed: false)
                        }
                        .buttonStyle(.plain)
                        .help("unpin from this moment")
                    }
                    MomentPicker(moments: moments.filter { !pinnedMoments.contains($0.id) }) { _ = pinnedMoments.insert($0) } label: {
                        pinChip("+ moment", fill: .clear, ink: Tokens.Palette.ink, dashed: true)
                    }
                }
            }
            Spacer(minLength: 8)
            Button("pin this note") {
                let subjects = (pinToPerson ? [ContextNote.Subject.person(person.id)] : []) + pinnedMoments.sorted().map { ContextNote.Subject.moment($0) }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    model.pinNote(draft, to: subjects)
                }
                draft = ""
            }
            .buttonStyle(HardShadowButtonStyle(fill: Tokens.Palette.grape, text: Tokens.TextStyle(.fredoka(.semibold), 17), padding: EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24), shadowOffset: Tokens.Shadows.hardOffsetSmall))
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!pinToPerson && pinnedMoments.isEmpty))
            .keyboardShortcut(.return, modifiers: .command)
        }
    }

    private func pinChip(_ label: String, fill: Color, ink: Color, dashed: Bool) -> some View {
        Text(label)
            .font(Tokens.Typeface.fredoka(.semibold).font(size: 13))
            .foregroundStyle(ink)
            .lineLimit(1)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(Tokens.Palette.ink, style: StrokeStyle(lineWidth: dashed ? 2 : 0, dash: [4, 3])))
            .fixedSize()
    }
}

/// One pinned note, written on the pad.
private struct NoteParagraph: View {
    let note: ContextNote
    let tag: String
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        (Text(note.body)
            .font(Tokens.Typeface.caveat(bold: false).font(size: 25))
            .foregroundStyle(Tokens.Palette.ink)
            + Text("   📌 \(tag)")
            .font(Tokens.Typeface.mono(bold: false).font(size: 10))
            .foregroundStyle(Tokens.Palette.pencil))
            .lineSpacing(ContextNotesView.handwritingSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                if hovering {
                    Button(action: onDelete) {
                        Text("✕ unpin")
                            .font(Tokens.Typeface.mono(bold: false).font(size: 10))
                            .foregroundStyle(Tokens.Palette.coral)
                            .padding(.horizontal, 6)
                            .background(Capsule().fill(Tokens.Palette.card))
                    }
                    .buttonStyle(.plain)
                    .offset(y: -6)
                }
            }
            .onHover { hovering = $0 }
            .contextMenu { Button("Unpin note", role: .destructive, action: onDelete) }
    }
}

/// Blue ruled lines on the notepad.
struct RuledLines: View {
    var top: CGFloat
    var spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var y = top
            while y < size.height + spacing {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Color(hex: 0xBFD3FF)))
                y += spacing
            }
        }
        .frame(minHeight: 800)
        .allowsHitTesting(false)
    }
}

/// A sheet torn off a pad: little ragged bites out of the left edge.
struct NotepadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bite = rect.width * 0.015
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        for fraction in [0.96, 0.94, 0.92, 0.08, 0.06, 0.04] {
            let x = [0.94, 0.06].contains(fraction) ? rect.minX + bite : rect.minX
            path.addLine(to: CGPoint(x: x, y: rect.minY + rect.height * fraction))
        }
        path.closeSubpath()
        return path
    }
}

/// "+ moment": a menu of moments to pin to (a plain chip in snapshots).
private struct MomentPicker<Label: View>: View {
    let moments: [Moment]
    let pick: (String) -> Void
    @ViewBuilder var label: Label
    @Environment(\.isRenderingSnapshot) private var isRenderingSnapshot

    init(moments: [Moment], pick: @escaping (String) -> Void, @ViewBuilder label: () -> Label) {
        self.moments = moments
        self.pick = pick
        self.label = label()
    }

    var body: some View {
        if isRenderingSnapshot {
            label
        } else {
            Menu {
                ForEach(moments) { moment in
                    Button(moment.title) { pick(moment.id) }
                }
            } label: {
                label
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(moments.isEmpty)
        }
    }
}
