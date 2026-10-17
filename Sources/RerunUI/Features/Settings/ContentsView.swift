import AppKit
import RerunCore
import SwiftUI
import UniformTypeIdentifiers

/// 10 — "Contents: everything rerun is allowed to do", as a table of contents
/// on a taped-down sheet.
struct ContentsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var addingTopic = false
    @State private var newTopic = ""
    @State private var confirmingErase = false
    @State private var exported = false

    var body: some View {
        ZStack {
            DotGrid()
            sheet
                .padding(EdgeInsets(top: 30, leading: 44, bottom: 30, trailing: 44))
        }
        .confirmationDialog("Erase your whole world?", isPresented: $confirmingErase, titleVisibility: .visible) {
            Button("Erase \(model.map.momentCount) moments, notes and stories", role: .destructive) { model.eraseWorld() }
            Button("Keep everything", role: .cancel) {}
        } message: {
            Text("This deletes everything rerun made on this Mac. Your real Messages are untouched.")
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                Text("Contents")
                    .textStyle(Tokens.Typography.displayTitle)
                    .foregroundStyle(Tokens.Palette.ink)
                Text("everything rerun is allowed to do")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 24))
                    .foregroundStyle(Tokens.Palette.pencil)
                Spacer()
                if model.isSampleWorld {
                    Text("SAMPLE WORLD")
                        .textStyle(Tokens.TextStyle(.mono(bold: true), 10, tracking: 2))
                        .foregroundStyle(Tokens.Palette.coral)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Tokens.Palette.coral, lineWidth: 2))
                        .rotationEffect(.degrees(4))
                        .help("Changes to the sample world aren't saved. Settings below are.")
                }
            }
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(Tokens.Palette.ink).frame(height: 3) }

            AdaptiveScroll(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    conversations
                    storyStyle
                    storyModel
                    offLimits
                    privacy
                }
                .padding(.bottom, 6)
            }
        }
        .padding(EdgeInsets(top: 34, leading: 46, bottom: 34, trailing: 46))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Tokens.Palette.card)
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.18), blur: 24, y: 12))
        .overlay(alignment: .topLeading) { Tape(width: 90, height: 24, angle: -4).offset(x: 60, y: -12) }
        .overlay(alignment: .topTrailing) { Tape(Tokens.Palette.tapeBlue, width: 80, height: 22, angle: 5).offset(x: -70, y: -10) }
        .rotationEffect(.degrees(-0.6))
    }

    // MARK: I. Conversations included

    private var conversations: some View {
        section("I.", Tokens.Palette.coral, "Conversations included", "\(model.includedPeople.count) of \(model.people.count)") {
            FlowLayout(spacing: 8) {
                ForEach(model.people) { person in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { model.setIncluded(person.id, !person.included) }
                    } label: {
                        personChip(person)
                    }
                    .buttonStyle(.plain)
                    .help(person.included ? "Leave \(person.displayName) out of stories" : "Bring \(person.displayName) back")
                }
            }
        }
    }

    @ViewBuilder
    private func personChip(_ person: Person) -> some View {
        if person.included {
            HStack(spacing: 6) {
                Text("✓")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(person.color == .sun ? Tokens.Palette.ink : person.color.fill)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.white))
                Text(person.displayName).font(Tokens.Typeface.fredoka(.semibold).font(size: 14))
            }
            .foregroundStyle(person.color.onFill)
            .padding(EdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 12))
            .background(Capsule().fill(person.color.fill))
        } else {
            HStack(spacing: 6) {
                Circle().strokeBorder(Tokens.Palette.pencilLine, lineWidth: 1.5).frame(width: 16, height: 16)
                Text(person.displayName).font(Tokens.Typeface.fredoka(.medium).font(size: 14))
            }
            .foregroundStyle(Tokens.Palette.pencil)
            .padding(EdgeInsets(top: 6, leading: 7, bottom: 6, trailing: 14))
            .overlay(Capsule().strokeBorder(Tokens.Palette.pencilLine, style: StrokeStyle(lineWidth: 2, dash: [5, 3])))
        }
    }

    // MARK: II. Story style

    private var storyStyle: some View {
        section("II.", Tokens.Palette.blue, "Story style", model.settings.storyStyle.label) {
            HStack(spacing: 14) {
                HStack(spacing: 0) {
                    ForEach(StoryStyle.allCases, id: \.self) { style in
                        let selected = model.settings.storyStyle == style
                        Button {
                            model.updateSettings { $0.storyStyle = style }
                        } label: {
                            Text(style.label)
                                .font(Tokens.Typeface.fredoka(.semibold).font(size: 14))
                                .foregroundStyle(selected ? Color.white : Tokens.Palette.ink)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(selected ? Tokens.Palette.blue : Color.clear)
                                .overlay(alignment: .leading) {
                                    if style != StoryStyle.allCases.first { Rectangle().fill(Tokens.Palette.ink).frame(width: Tokens.Stroke.outline) }
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Tokens.Palette.ink, lineWidth: Tokens.Stroke.outline))
                .fixedSize()
                Text("how far stories can drift from what really happened")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                    .foregroundStyle(Tokens.Palette.pencil)
            }
        }
    }

    // MARK: III. Story model

    private var storyModel: some View {
        section("III.", Tokens.Palette.sunLine, "Story model", model.settings.storyModel.label) {
            HStack(spacing: 12) {
                modelCard(
                    .onDevice,
                    title: "On this Mac",
                    detail: model.onDeviceAvailable ? "private · slower · M-series chip" : OnDeviceModel.unavailableReason,
                    available: model.onDeviceAvailable
                )
                modelCard(.cloud, title: "Cloud model, your API key", detail: "sends story prompts only — never full threads", available: true)
                SettingsLink {
                    Text("keys & routing →")
                        .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                        .foregroundStyle(Tokens.Palette.blue)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func modelCard(_ choice: StoryModelChoice, title: String, detail: String, available: Bool) -> some View {
        let selected = model.settings.storyModel == choice
        return Button {
            model.updateSettings { $0.storyModel = choice }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(selected ? Tokens.Palette.ink : Color.clear)
                    .padding(selected ? 4 : 0)
                    .overlay(Circle().strokeBorder(selected ? Tokens.Palette.ink : Tokens.Palette.pencilLine, lineWidth: 2))
                    .frame(width: 16, height: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Tokens.Typeface.fredoka(.semibold).font(size: 15))
                    Text(detail)
                        .textStyle(Tokens.TextStyle(.mono(bold: false), 10))
                        .foregroundStyle(selected ? Tokens.Palette.ink : Tokens.Palette.pencil)
                }
                .foregroundStyle(Tokens.Palette.ink)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Tokens.Palette.sun : Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Color.white : Tokens.Palette.perforation, lineWidth: selected ? 3 : 2))
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Tokens.Palette.ink : .clear).padding(-2))
            .rotationEffect(.degrees(selected ? -1 : 0))
            .opacity(available ? 1 : 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!available)
    }

    // MARK: IV. Off-limits topics

    private var offLimits: some View {
        section("IV.", Tokens.Palette.grape, "Off-limits topics", "\(model.settings.offLimitsTopics.count) skipped") {
            FlowLayout(spacing: 8) {
                ForEach(model.settings.offLimitsTopics, id: \.self) { topic in
                    Button {
                        model.updateSettings { $0.offLimitsTopics.removeAll { $0 == topic } }
                    } label: {
                        Text(topic)
                            .font(Tokens.Typeface.fredoka(.semibold).font(size: 14))
                            .strikethrough(true, color: Tokens.Palette.coral)
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Tokens.Palette.ink))
                    }
                    .buttonStyle(.plain)
                    .help("Allow “\(topic)” again")
                }
                Button { addingTopic = true } label: {
                    Text("+ add topic")
                        .font(Tokens.Typeface.fredoka(.semibold).font(size: 14))
                        .foregroundStyle(Tokens.Palette.ink)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Tokens.Palette.ink, style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $addingTopic, arrowEdge: .bottom) { topicField }
                Toggle(isOn: Binding(get: { model.settings.neverInventBreakupsOrDeaths }, set: { value in model.updateSettings { $0.neverInventBreakupsOrDeaths = value } })) {
                    Text("never invent breakups or deaths").font(Tokens.Typeface.fredoka(.medium).font(size: 14))
                }
                .toggleStyle(StickerToggleStyle())
                .padding(.leading, 14)
            }
        }
    }

    private var topicField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEVER BRING UP").textStyle(Tokens.Typography.monoEyebrow).foregroundStyle(Tokens.Palette.pencil)
            TextField("e.g. the job thing", text: $newTopic)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .onSubmit(addTopic)
            Button("add", action: addTopic)
                .buttonStyle(PillButtonStyle(fill: Tokens.Palette.ink, foreground: .white, border: Tokens.Palette.ink, text: Tokens.Typography.pill, padding: EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12)))
                .disabled(newTopic.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
    }

    private func addTopic() {
        let topic = newTopic.trimmingCharacters(in: .whitespaces)
        guard !topic.isEmpty else { return }
        model.updateSettings { if !$0.offLimitsTopics.contains(topic) { $0.offLimitsTopics.append(topic) } }
        newTopic = ""
        addingTopic = false
    }

    // MARK: V. Privacy & your data

    private var privacy: some View {
        section("V.", Tokens.Palette.leaf, "Privacy & your data", model.storageLabel) {
            HStack(spacing: 12) {
                Button("Rescan Messages") { model.rescan() }
                    .buttonStyle(OutlinePillButtonStyle())
                Button(exported ? "Exported ✓" : "Export my notes") { export() }
                    .buttonStyle(OutlinePillButtonStyle())
                    .disabled(model.notes.isEmpty)
                Button("Erase my world") { confirmingErase = true }
                    .buttonStyle(HardShadowButtonStyle(text: Tokens.Typography.pill, padding: EdgeInsets(top: 6.5, leading: 15.5, bottom: 6.5, trailing: 15.5), shadowOffset: 3))
                    .disabled(model.isSampleWorld)
                Text("deletes all \(model.map.momentCount) moments.\nyour real Messages are untouched.")
                    .textStyle(Tokens.TextStyle(.caveat(bold: false), 18, lineHeight: 1.05))
                    .foregroundStyle(Tokens.Palette.pencil)
            }
        }
    }

    private func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "rerun-context-notes.md"
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try model.notesExport().write(to: url, atomically: true, encoding: .utf8)
            exported = true
        } catch {
            model.lastError = "Couldn't export: \(error.localizedDescription)"
        }
    }

    // MARK: Section chrome

    /// "I.  Conversations included ··········· 5 of 7"
    private func section<Content: View>(_ numeral: String, _ color: Color, _ title: String, _ value: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(numeral)
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 13))
                    .foregroundStyle(color)
                    .frame(width: 26, alignment: .leading)
                Text(title)
                    .textStyle(Tokens.Typography.sectionTitle)
                    .foregroundStyle(Tokens.Palette.ink)
                LineShape()
                    .stroke(Tokens.Palette.pencilLine, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 4]))
                    .frame(height: 2)
                Text(value)
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 13))
                    .foregroundStyle(Tokens.Palette.ink)
            }
            content().padding(.leading, 38)
        }
    }
}
