import RerunCore
import SwiftUI

/// The torn kraft strip on the left: wordmark, nav stickers, people, privacy note.
struct Sidebar: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            KraftPaper()
                .clipShape(TornEdgeShape())
                .shadow(Tokens.Shadows.sidebarEdge)
                .frame(width: Tokens.Metrics.sidebarWidth + Tokens.Metrics.sidebarTear)

            VStack(alignment: .leading, spacing: Tokens.Space.xl) {
                header
                nav
                people
                Spacer(minLength: 0)
                privacyNote
            }
            .padding(Tokens.Metrics.sidebarPadding)
            .frame(width: Tokens.Metrics.sidebarWidth, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: Tokens.Metrics.sidebarWidth + Tokens.Metrics.sidebarTear, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Wordmark()
                .overlay(alignment: .topTrailing) {
                    Doodle.star
                        .foregroundStyle(Tokens.Palette.sun)
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(15))
                        .offset(x: 14, y: -4)
                }
            Text("\(model.player.name.uppercased())'S WORLD · \(model.map.momentCount) MOMENTS")
                .textStyle(Tokens.Typography.monoCaption.withTracking(0.5))
                .foregroundStyle(Tokens.Palette.pencil)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var nav: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            ForEach(Screen.allCases) { screen in
                NavItem(screen: screen, isActive: model.screen == screen) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { model.go(to: screen) }
                }
                .keyboardShortcut(screen.shortcut, modifiers: .command)
            }
        }
    }

    private var people: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("PEOPLE")
                .textStyle(Tokens.Typography.monoEyebrow)
                .foregroundStyle(Tokens.Palette.pencil)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(model.includedPeople.prefix(5)) { person in
                    Button { model.openStoryline(person.id) } label: {
                        HStack(spacing: Tokens.Space.sm) {
                            Circle()
                                .fill(person.color.fill)
                                .frame(width: Tokens.Metrics.avatarSmall, height: Tokens.Metrics.avatarSmall)
                                .padding(Tokens.Stroke.chip)
                                .background(Circle().fill(Color.white))
                                .shadow(Tokens.Shadows.avatar)
                            Text(person.displayName)
                                .textStyle(Tokens.Typography.personRow)
                                .foregroundStyle(Tokens.Palette.ink)
                                .lineLimit(1)
                            Spacer(minLength: Tokens.Space.xs)
                            Text(Self.compactCount(person.momentCount > 0 ? person.momentCount : person.messageCount))
                                .textStyle(Tokens.Typography.monoCaption)
                                .foregroundStyle(Tokens.Palette.pencil)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("\(person.displayName)'s storyline")
                }
            }
        }
    }

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text("● ").foregroundStyle(Tokens.Palette.leaf) + Text("all processing on this mac"))
            Text(scanLine)
            if model.isSampleWorld {
                Button("scan my messages →") { model.onboarding = .privacy }
                    .buttonStyle(UnderlineLinkButtonStyle(text: Tokens.TextStyle(.caveat(bold: true), 17), color: Tokens.Palette.coral))
                    .padding(.top, 4)
            }
        }
        .textStyle(Tokens.Typography.monoCaption.withLineHeight(1.5))
        .foregroundStyle(Tokens.Palette.pencilDark)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .dashedBox()
        .rotationEffect(.degrees(Tokens.Tilt.sidebarNote))
    }

    private var scanLine: String {
        if model.isSampleWorld { return "sample world · not scanned yet" }
        guard let date = model.settings.lastScanAt else { return "not scanned yet" }
        return "last scan · " + Self.scanDate(date)
    }

    static func compactCount(_ count: Int) -> String {
        count >= 10_000 ? String(format: "%.0fk", Double(count) / 1000)
            : count >= 1_000 ? String(format: "%.1fk", Double(count) / 1000)
            : "\(count)"
    }

    /// "today 9:14 am", "yesterday 6:02 pm", "oct 12"
    static func scanDate(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let time = DateFormatter.rerun("h:mm a").string(from: date).lowercased()
        if calendar.isDate(date, inSameDayAs: now) { return "today \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "yesterday \(time)"
        }
        return DateFormatter.rerun("MMM d").string(from: date).lowercased()
    }
}

/// One nav row. Active: a tilted color sticker. Inactive: a small tilted swatch.
private struct NavItem: View {
    let screen: Screen
    let isActive: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            if isActive {
                HStack(spacing: Tokens.Space.m) {
                    Text(screen.number)
                        .textStyle(Tokens.Typography.monoCaption)
                        .opacity(0.8)
                    Text(screen.label)
                        .textStyle(Tokens.Typography.navItemActive)
                }
                .foregroundStyle(screen.color.onFill)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sticker(screen.color.fill, borderWidth: Tokens.Stroke.button, radius: Tokens.Radius.control)
                .rotationEffect(.degrees(Tokens.Tilt.navActive))
                .shadows(Tokens.Shadows.navActive)
                .padding(.horizontal, -4)
                .padding(.vertical, 3)
            } else {
                HStack(spacing: Tokens.Space.m) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(screen.color.fill)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(14))
                    Text(screen.label)
                        .textStyle(Tokens.Typography.navItem)
                        .foregroundStyle(Tokens.Palette.ink)
                    Spacer(minLength: 0)
                    if hovering {
                        Text("⌘\(screen.number.suffix(1))")
                            .textStyle(Tokens.TextStyle(.mono(bold: false), 9))
                            .foregroundStyle(Tokens.Palette.pencil)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.Radius.note)
                        .fill(Tokens.Palette.card.opacity(hovering ? 0.55 : 0))
                )
                .contentShape(Rectangle())
                .onHover { inside in withAnimation(.easeOut(duration: 0.12)) { hovering = inside } }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

extension DateFormatter {
    static func rerun(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}
