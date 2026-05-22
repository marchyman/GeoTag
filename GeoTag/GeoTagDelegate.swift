import AppKit
import OSLog
import UDF

// AppDelegate for things that can (not yet?) be done using a
// pure SwiftUI life cycle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var store: Store<GeoTagState, GeoTagEvent>?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                        category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("\(#function): store is \(self.store == nil ? "nil" : "set", privacy: .public)")
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let store {
            OpenHelper.open(store, urls: urls, description: "open with",
                            spinnerEnabled: nil)
            if store.mainWindow?.isVisible == false {
                store.mainWindow?.orderFront(self)
            }
        } else {
            logger.error("\(#function): store not set")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows: Bool) -> Bool {
        // orderFront the main window if not visible.
        for window in sender.windows where window == store?.mainWindow {
            if !window.isVisible {
                window.orderFront(self)
                return false
            }
        }
        return true
    }

    // can not use: calls to application(_, open) when the app is running
    // will otherwise quit the program as macOS closes the window.
    // func applicationShouldTerminateAfterLastWindowClosed(
    //     _ theApplication: NSApplication) -> Bool {
    //     return true
    // }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        logger.info("\(#function)")
        if let store {
            if store.saveInProgress || store.unsavedChanges {
                store.send(.quitRequested, undoable: false)
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("\(#function)")
        let environ = ProcessInfo.processInfo.environment
        if environ["APP_SANDBOX_CONTAINER_ID"] != nil {
            // we're sandboxed -- blow away the sandbox document directory
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: URL.documentsDirectory)
        }
    }

    // GeoTag needs this delegate to stop the windows from closing
    // when changes are pending.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let store {
            if store.saveInProgress || store.unsavedChanges {
                store.send(.quitRequested, undoable: false)
                return false
            }
        }
        return true
    }
}
