import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = NSDocumentController.shared
        NSApp.mainMenu = MainMenu.build()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Files opened from Finder / `open` arrive around launch; only show the
        // open panel if nothing showed up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if NSDocumentController.shared.documents.isEmpty && NSApp.windows.allSatisfy({ !$0.isVisible }) {
                NSDocumentController.shared.openDocument(nil)
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSDocumentController.shared.openDocument(nil) }
        return false
    }

    // A viewer has no reason to linger in memory once its last window is gone.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
