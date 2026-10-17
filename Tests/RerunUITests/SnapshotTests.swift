import AppKit
import RerunCore
@testable import RerunUI
import SwiftUI
import XCTest

/// Renders screens offscreen at the mockup's 1200×780 window size so they can
/// be compared with Rerun_App.html. Set RERUN_SNAPSHOT_DIR to write PNGs.
@MainActor
final class SnapshotTests: XCTestCase {
    func testBundledFontsRegister() {
        FontRegistry.registerBundledFonts()
        for name in ["Fredoka-Regular", "Fredoka-Medium", "Fredoka-SemiBold", "Fredoka-Bold", "Caveat-Medium", "Caveat-Bold", "SpaceMono-Regular", "SpaceMono-Bold"] {
            XCTAssertNotNil(NSFont(name: name, size: 12), "\(name) isn't registered")
        }
    }

    func testWorldMapSnapshot() throws {
        let model = AppModel.sample()
        try snapshot(RootView().environmentObject(model), named: "world-map")
    }

    func testMomentPreviewSnapshot() throws {
        let model = AppModel.sample()
        model.openMomentID = "lisbon"
        try snapshot(RootView().environmentObject(model), named: "moment-preview")
    }

    private func snapshot(_ view: some View, named name: String) throws {
        FontRegistry.registerBundledFonts()
        let renderer = ImageRenderer(content: view
            .environment(\.isRenderingSnapshot, true)
            .frame(width: Tokens.Metrics.windowWidth, height: Tokens.Metrics.windowHeight))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage, "nothing rendered")
        XCTAssertEqual(image.width, Int(Tokens.Metrics.windowWidth))

        guard let directory = ProcessInfo.processInfo.environment["RERUN_SNAPSHOT_DIR"] else { return }
        let png = try XCTUnwrap(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try png.write(to: url)
    }
}
