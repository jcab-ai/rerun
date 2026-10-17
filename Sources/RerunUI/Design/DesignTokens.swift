import AppKit
import RerunCore
import SwiftUI

// Design tokens for rerun, taken from the mockup (Rerun_App.html). Values are
// CSS pixels from the mockup, which map 1:1 to points on macOS. Names describe
// the role; comments name where the mockup uses them.

public enum Tokens {}

// MARK: - Color

extension Tokens {
    public enum Palette {
        // Ink & paper
        /// #1C1830 — all text, outlines, hard button shadows, the "you" node.
        public static let ink = Color(hex: 0x1C1830)
        /// #3A3448 — long-form body copy.
        public static let inkSoft = Color(hex: 0x3A3448)
        /// #4A4458 — window title text.
        public static let inkMuted = Color(hex: 0x4A4458)
        /// #FFF8EC — app background under the dot grid.
        public static let paper = Color(hex: 0xFFF8EC)
        /// #FFFDF7 — torn paper cards, "paper" stickers, handwritten label backs.
        public static let card = Color(hex: 0xFFFDF7)
        /// #E6D3B3 — kraft paper: sidebar, title bar, evidence board, play table.
        public static let kraft = Color(hex: 0xE6D3B3)
        /// #F4EBDB — lighter title bar used during onboarding.
        public static let kraftLight = Color(hex: 0xF4EBDB)
        /// #2A2440 — dimmed backdrop behind the moment detail card.
        public static let night = Color(hex: 0x2A2440)

        // Pencil browns
        /// #6B5A44 — mono labels, captions, handwriting.
        public static let pencil = Color(hex: 0x6B5A44)
        /// #5A4A36 — fine print in dashed boxes.
        public static let pencilDark = Color(hex: 0x5A4A36)
        /// #8C7656 — dashed borders, dotted leaders.
        public static let pencilLine = Color(hex: 0x8C7656)
        /// #C9BFA9 — ticket perforations, unselected outlines.
        public static let perforation = Color(hex: 0xC9BFA9)

        // Sticker colors
        /// #FF5B45 — primary action, Maya, nav "World map".
        public static let coral = Color(hex: 0xFF5B45)
        /// #FF8A6B — coral highlight (pushpins, avatar gradients).
        public static let coralLight = Color(hex: 0xFF8A6B)
        /// #D63A26 — coral shadow (pushpins).
        public static let coralDeep = Color(hex: 0xD63A26)
        /// #2D5BFF
        public static let blue = Color(hex: 0x2D5BFF)
        /// #FFC42E — needs ink text on top.
        public static let sun = Color(hex: 0xFFC42E)
        /// #E0A800 — yellow when it's a line on paper (map edges, roman numerals).
        public static let sunLine = Color(hex: 0xE0A800)
        /// #2FB65A
        public static let leaf = Color(hex: 0x2FB65A)
        /// #8A4DFF
        public static let grape = Color(hex: 0x8A4DFF)

        // Washi tape
        public static let tapeYellow = Color(.sRGB, red: 255 / 255, green: 236 / 255, blue: 170 / 255, opacity: 0.85)
        public static let tapeBlue = Color(.sRGB, red: 150 / 255, green: 190 / 255, blue: 255 / 255, opacity: 0.8)
        public static let tapePink = Color(.sRGB, red: 255 / 255, green: 170 / 255, blue: 190 / 255, opacity: 0.8)

        /// Kraft paper fibre stripes, rgba(120,90,50,.05).
        public static let kraftFibre = Color(.sRGB, red: 120 / 255, green: 90 / 255, blue: 50 / 255, opacity: 0.05)
        /// Background dot grid, ink at 7%.
        public static let dotGrid = ink.opacity(0.07)
        /// Hairline under the title bar, ink at 12%.
        public static let hairline = ink.opacity(0.12)
        /// Inactive progress pips, ink at 15–18%.
        public static let pipOff = ink.opacity(0.18)

        /// The simulated iMessage UI on the play screen.
        public enum Messages {
            public static let bubbleThem = Color(hex: 0xE9E9EB)
            public static let bubbleMe = Color(hex: 0x0A84FF)
            public static let meta = Color(hex: 0x8E8E93)
            public static let separator = Color(hex: 0xD8D8DC)
            public static let header = Color(hex: 0xF8F8FA)
            public static let fieldBorder = Color(hex: 0xD1D1D6)
            public static let placeholder = Color(hex: 0xC7C7CC)
        }
    }
}

extension PersonColor {
    /// Sticker fill.
    public var fill: Color {
        switch self {
        case .coral: Tokens.Palette.coral
        case .blue: Tokens.Palette.blue
        case .leaf: Tokens.Palette.leaf
        case .grape: Tokens.Palette.grape
        case .sun: Tokens.Palette.sun
        }
    }

    /// The color as a line on paper; yellow darkens so it stays visible.
    public var line: Color { self == .sun ? Tokens.Palette.sunLine : fill }

    /// Text drawn on top of `fill`.
    public var onFill: Color { self == .sun ? Tokens.Palette.ink : .white }
}

extension Color {
    /// sRGB color from 0xRRGGBB.
    public init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Typography

extension Tokens {
    /// The mockup's three families plus the system font for iMessage and chrome.
    public enum Typeface: Hashable {
        /// Fredoka — rounded display + UI text.
        case fredoka(Weight)
        /// Caveat — handwritten notes. Medium is the mockup's default weight.
        case caveat(bold: Bool)
        /// Space Mono — labels, dates, metadata.
        case mono(bold: Bool)
        /// -apple-system — window titles and iMessage bubbles.
        case system(Font.Weight)

        public enum Weight: Hashable { case regular, medium, semibold, bold }

        public var postScriptName: String? {
            switch self {
            case .fredoka(.regular): "Fredoka-Regular"
            case .fredoka(.medium): "Fredoka-Medium"
            case .fredoka(.semibold): "Fredoka-SemiBold"
            case .fredoka(.bold): "Fredoka-Bold"
            case .caveat(let bold): bold ? "Caveat-Bold" : "Caveat-Medium"
            case .mono(let bold): bold ? "SpaceMono-Bold" : "SpaceMono-Regular"
            case .system: nil
            }
        }

        public func font(size: CGFloat) -> Font {
            switch self {
            case .system(let weight): .system(size: size, weight: weight)
            default: .custom(postScriptName!, fixedSize: size)
            }
        }

        func nsFont(size: CGFloat) -> NSFont? {
            postScriptName.flatMap { NSFont(name: $0, size: size) } ?? .systemFont(ofSize: size)
        }
    }

    /// A text role: face, size, letter-spacing and CSS-style line height.
    public struct TextStyle: Hashable {
        public var face: Typeface
        public var size: CGFloat
        /// CSS letter-spacing in points.
        public var tracking: CGFloat
        /// CSS line-height as a multiple of the size; nil for "normal".
        public var lineHeight: CGFloat?

        public init(_ face: Typeface, _ size: CGFloat, tracking: CGFloat = 0, lineHeight: CGFloat? = nil) {
            self.face = face
            self.size = size
            self.tracking = tracking
            self.lineHeight = lineHeight
        }

        public var font: Font { face.font(size: size) }

        /// Extra space between lines to reach `lineHeight`. SwiftUI can only
        /// add leading, so line heights tighter than the font's own collapse to 0.
        public var lineSpacing: CGFloat {
            guard let lineHeight, let nsFont = face.nsFont(size: size) else { return 0 }
            let natural = nsFont.ascender - nsFont.descender + nsFont.leading
            return max(0, size * lineHeight - natural)
        }

        public func resized(_ size: CGFloat) -> TextStyle {
            var copy = self
            copy.size = size
            return copy
        }

        public func withTracking(_ tracking: CGFloat) -> TextStyle {
            var copy = self
            copy.tracking = tracking
            return copy
        }

        public func withLineHeight(_ lineHeight: CGFloat) -> TextStyle {
            var copy = self
            copy.lineHeight = lineHeight
            return copy
        }
    }

    public enum Typography {
        // Brand
        /// Sidebar "[rerun]" wordmark.
        public static let wordmark = TextStyle(.fredoka(.bold), 28, tracking: -0.5, lineHeight: 1)
        /// Welcome screen hero wordmark.
        public static let heroWordmark = TextStyle(.fredoka(.bold), 112, tracking: -4, lineHeight: 0.9)

        // Headings
        /// "Your world" — screen header on the map.
        public static let screenTitle = TextStyle(.fredoka(.bold), 28)
        /// Moment detail / settings big titles.
        public static let displayTitle = TextStyle(.fredoka(.bold), 46, tracking: -1, lineHeight: 1)
        /// Onboarding step headline.
        public static let headline = TextStyle(.fredoka(.bold), 42, tracking: -1.5, lineHeight: 1.02)
        /// Settings section title ("Conversations included").
        public static let sectionTitle = TextStyle(.fredoka(.semibold), 21)
        /// Play screen title next to the back pill.
        public static let barTitle = TextStyle(.fredoka(.bold), 20)

        // Body
        public static let body = TextStyle(.fredoka(.regular), 18, lineHeight: 1.5)
        public static let bodyCompact = TextStyle(.fredoka(.regular), 17, lineHeight: 1.45)
        public static let lede = TextStyle(.fredoka(.regular), 24, lineHeight: 1.3)

        // UI
        public static let navItem = TextStyle(.fredoka(.medium), 15)
        public static let navItemActive = TextStyle(.fredoka(.semibold), 15)
        public static let personRow = TextStyle(.fredoka(.regular), 14)
        public static let chip = TextStyle(.fredoka(.semibold), 13)
        public static let pill = TextStyle(.fredoka(.semibold), 14)
        public static let link = TextStyle(.fredoka(.medium), 16)
        public static let buttonLarge = TextStyle(.fredoka(.semibold), 22)
        public static let buttonPlay = TextStyle(.fredoka(.bold), 24)
        public static let choice = TextStyle(.fredoka(.semibold), 16, lineHeight: 1.25)

        // World map
        public static let nodeTitle = TextStyle(.fredoka(.semibold), 15, lineHeight: 1.1)
        public static let nodeTitleFeatured = TextStyle(.fredoka(.semibold), 17, lineHeight: 1.1)
        public static let youLabel = TextStyle(.fredoka(.bold), 38, lineHeight: 1)

        // Mono labels
        /// Sticker metadata ("JUN 14 '24 · MAYA").
        public static let monoMicro = TextStyle(.mono(bold: false), 9)
        /// Captions, counts, legend.
        public static let monoCaption = TextStyle(.mono(bold: false), 10)
        /// Section eyebrows ("PEOPLE", "STARRING").
        public static let monoEyebrow = TextStyle(.mono(bold: false), 10, tracking: 1)
        /// Date chips, step counters.
        public static let monoSmall = TextStyle(.mono(bold: false), 11)
        public static let monoBody = TextStyle(.mono(bold: false), 14)

        // Handwriting
        public static let handBadge = TextStyle(.caveat(bold: true), 17)
        public static let handSmall = TextStyle(.caveat(bold: false), 19)
        public static let handCaption = TextStyle(.caveat(bold: false), 20)
        public static let handNote = TextStyle(.caveat(bold: false), 22)
        public static let handLarge = TextStyle(.caveat(bold: false), 24)

        // System
        public static let windowTitle = TextStyle(.system(.semibold), 13)
        public static let bubble = TextStyle(.system(.regular), 13.5, lineHeight: 1.3)
    }
}

// MARK: - Spacing & sizes

extension Tokens {
    /// The spacing steps the mockup uses.
    public enum Space {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 6
        public static let sm: CGFloat = 8
        public static let m: CGFloat = 10
        public static let ml: CGFloat = 12
        public static let l: CGFloat = 14
        public static let lx: CGFloat = 16
        public static let xl: CGFloat = 18
        public static let xxl: CGFloat = 22
        public static let xxxl: CGFloat = 26
        public static let huge: CGFloat = 34
    }

    public enum Metrics {
        public static let windowWidth: CGFloat = 1200
        public static let windowHeight: CGFloat = 780
        public static let titleBarHeight: CGFloat = 30
        public static let sidebarWidth: CGFloat = 220
        /// How far the torn kraft edge overlaps the content.
        public static let sidebarTear: CGFloat = 10
        public static let sidebarPadding = EdgeInsets(top: 22, leading: 18, bottom: 18, trailing: 18)
        public static let dotGridSpacing: CGFloat = 16
        public static let dotRadius: CGFloat = 1.2
        public static let mapHeaderHeight: CGFloat = 70
        public static let mapHeaderInsets = EdgeInsets(top: 0, leading: 34, bottom: 0, trailing: 26)
        public static let nodeWidth: CGFloat = 150
        public static let featuredNodeWidth: CGFloat = 178
        public static let youDiameter: CGFloat = 132
        public static let avatarSmall: CGFloat = 20
        public static let avatar: CGFloat = 36
    }

    public enum Radius {
        /// Tiny mono tags ("+48").
        public static let tag: CGFloat = 4
        /// Date chips.
        public static let chipSquare: CGFloat = 6
        /// Dashed note boxes, inactive nav rows.
        public static let note: CGFloat = 8
        /// Active nav sticker, zoom control, legend.
        public static let control: CGFloat = 10
        /// Moment stickers on the map.
        public static let sticker: CGFloat = 12
        /// Boarding-pass style sticker cards.
        public static let card: CGFloat = 14
        /// Choice buttons.
        public static let choice: CGFloat = 16
        /// Big info stickers (privacy cards, chapter card).
        public static let panel: CGFloat = 18
    }

    public enum Stroke {
        public static let hairline: CGFloat = 1
        public static let dashed: CGFloat = 1.5
        public static let chip: CGFloat = 2
        public static let outline: CGFloat = 2.5
        /// Hard-shadow buttons.
        public static let button: CGFloat = 3
        /// White sticker border on the map.
        public static let sticker: CGFloat = 4
        /// White border on big stickers.
        public static let panel: CGFloat = 5
        public static let you: CGFloat = 7
        /// Map edges from "you".
        public static let edge: CGFloat = 2.5
        /// Thin links between related moments.
        public static let link: CGFloat = 1.5
    }

    /// Fixed sticker tilts, in degrees.
    public enum Tilt {
        public static let navActive: Double = -2
        public static let headerNote: Double = -2
        public static let youCaption: Double = -3
        public static let playedBadge: Double = 10
        public static let legend: Double = 1.5
        public static let sidebarNote: Double = -1
        public static let chipStarring: [Double] = [-2, 1.5]
        public static let choices: [Double] = [-1.5, 1, -0.5]
    }
}

// MARK: - Shadows

extension Tokens {
    /// A CSS box-shadow: offset, blur, color. `blur` is the CSS blur radius.
    public struct Shadow: Hashable {
        public var color: Color
        public var blur: CGFloat
        public var x: CGFloat
        public var y: CGFloat

        public init(_ color: Color, blur: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.blur = blur
            self.x = x
            self.y = y
        }
    }

    public enum Shadows {
        private static let ink = Palette.ink
        /// 0 6px 16px ink/.22 — map stickers.
        public static let sticker = Shadow(ink.opacity(0.22), blur: 16, y: 6)
        /// 0 12px 24px ink/.30 — the featured sticker.
        public static let stickerFeatured = Shadow(ink.opacity(0.3), blur: 24, y: 12)
        /// 0 10px 24px ink/.25 — big stickers on onboarding.
        public static let panel = Shadow(ink.opacity(0.25), blur: 24, y: 10)
        /// 0 14px 30px ink/.35 — the "you" node.
        public static let you = Shadow(ink.opacity(0.35), blur: 30, y: 14)
        /// 0 2px 0 ink/.12 + 0 6px 14px ink/.18 — active nav sticker.
        public static let navActive = [Shadow(ink.opacity(0.12), blur: 0, y: 2), Shadow(ink.opacity(0.18), blur: 14, y: 6)]
        /// 0 1px 3px black/.2 — small avatars.
        public static let avatar = Shadow(Color.black.opacity(0.2), blur: 3, y: 1)
        /// 0 4px 12px ink/.15 — legend, floating labels.
        public static let floating = Shadow(ink.opacity(0.15), blur: 12, y: 4)
        /// 0 3px 10px ink/.15 — "starring" person pills.
        public static let pill = Shadow(ink.opacity(0.15), blur: 10, y: 3)
        /// drop-shadow(3px 0 4px ink/.12) — the sidebar's torn edge.
        public static let sidebarEdge = Shadow(ink.opacity(0.12), blur: 4, x: 3)
        /// drop-shadow(0 14px 26px ink/.28) — torn paper cards.
        public static let paperCard = Shadow(ink.opacity(0.28), blur: 26, y: 14)
        /// Hard offset ink shadow under buttons: 5px 5px 0.
        public static let hardOffset: CGFloat = 5
        public static let hardOffsetHover: CGFloat = 7
        public static let hardOffsetSmall: CGFloat = 4
    }
}

extension View {
    /// Applies a mockup box-shadow. SwiftUI's radius is about half the CSS blur.
    public func shadow(_ token: Tokens.Shadow) -> some View {
        shadow(color: token.color, radius: token.blur / 2, x: token.x, y: token.y)
    }

    public func shadows(_ tokens: [Tokens.Shadow]) -> some View {
        tokens.reduce(AnyView(self)) { view, token in AnyView(view.shadow(token)) }
    }

    /// Font, letter-spacing and line height for a text role.
    public func textStyle(_ style: Tokens.TextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}
