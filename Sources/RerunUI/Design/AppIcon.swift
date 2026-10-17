import AppKit

/// The [r] sticker icon. The Xcode app gets it from its asset catalog;
/// `swift run` builds have no bundle, so set it on the running app instead.
public enum AppIcon {
    public static var image: NSImage? {
        Bundle.module.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Icon").flatMap(NSImage.init(contentsOf:))
    }

    public static func applyForDevelopmentBuild() {
        if let image { NSApplication.shared.applicationIconImage = image }
    }
}
