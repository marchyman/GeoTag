import AppKit
import OSLog
import UDF

// AppDelegate for things that can (not yet?) be done using a
// pure SwiftUI life cycle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: Store<GeoTagState, GeoTagEvent>?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                        category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("\(#function): store is \(self.store == nil ? "nil" : "set")")
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        logger.info("\(#function)")
        // event to process given urls
    }

    func applicationShouldTerminate(_ sender: NSApplication)
        -> NSApplication.TerminateReply {
        logger.info("\(#function)")
        if let store {
            if store.saveInProgress || store.isDocumentEdited {
                store.send(.quitRequested) 
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
}
