//
//  AppDelegate.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import AppKit

/// GeoTag AppDelegate Class
///
/// App Delegate needed to get some desired behaviors such as terminate app when window closed
final class AppDelegate: NSObject, NSApplicationDelegate {
    var avm: AppViewModel?

    // things that can not (yet?) be done in SwiftUI (or can be done but
    // I don't know how so do it this way).

    func applicationDidFinishLaunching(_ notification: Notification) {
        // no tabbing in GeoTag
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    // Process open with...

    func application(_ application: NSApplication, open urls: [URL]) {
        Task {
            await self.avm?.prepareForEdit(inputURLs: urls)
        }
    }

    // Called when window that was hidden is now visible

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        // print("flag is \(flag)")
        return true
    }

    // quit the app when it's window is closed.

    func applicationShouldTerminateAfterLastWindowClosed(_ theApplication: NSApplication) -> Bool {
        return true
    }

    // Check if there are changes that haven't been saved before allowing
    // the app to quit.

    @MainActor
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let avm {
            if avm.saveInProgress {
                ContentViewModel.shared.addSheet(type: .savingUpdatesSheet)
                return .terminateCancel
            }

            if let edited = avm.mainWindow?.isDocumentEdited, edited {
                ContentViewModel.shared.confirmationMessage =
                    "If you quit GeoTag before saving changes the changes will be lost.  Are you sure you want to quit?"
                ContentViewModel.shared.confirmationAction = terminateIgnoringEdits
                ContentViewModel.shared.presentConfirmation = true
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    // passed as the action method to terminate confirmation view and
    // called when the user wants to terminate without saving changes.

    @MainActor
    func terminateIgnoringEdits() {
        avm?.mainWindow?.isDocumentEdited = false
        NSApp.terminate(NSApp)
    }

    // remove up the app sandbox before going away.  There is nothing in
    // it that needs to be kept.

    func applicationWillTerminate(_ notification: Notification) {
        let environ = ProcessInfo.processInfo.environment
        if environ["APP_SANDBOX_CONTAINER_ID"] != nil {
            // we're sandboxed -- blow away the sandbox document directory
            let fileManager = FileManager.default
            if let docDir = try? fileManager.url(for: .documentDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: false) {
                try? fileManager.removeItem(at: docDir)
            }
        }
    }
}
