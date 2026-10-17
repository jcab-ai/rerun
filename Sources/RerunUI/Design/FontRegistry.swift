import CoreText
import Foundation

/// Registers the bundled Fredoka, Caveat and Space Mono fonts (SIL OFL, see
/// Resources/Fonts) for this process. Call once at launch, before any view draws.
public enum FontRegistry {
    private static var registered = false

    public static func registerBundledFonts() {
        guard !registered else { return }
        registered = true
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let message = error?.takeRetainedValue().localizedDescription ?? "unknown error"
                NSLog("rerun: couldn't register font \(url.lastPathComponent): \(message)")
            }
        }
    }
}
