//
//  AppDelegate.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import AppKit

// open with..., unsaved changes upon termination, and other checks

final class AppDelegate: NSObject, NSApplicationDelegate {
    var state: AppState?

    // things that can not (yet?) be done in SwiftUI (or can be done but
    // I don't know how so do it this way).

    func applicationDidFinishLaunching(_ notification: Notification) {
        // no tabbing in GeoTag
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    // Process open with...

    func application(_ application: NSApplication, open urls: [URL]) {
        Task.detached {
            await self.state?.prepareForEdit(inputURLs: urls)
        }
    }

    // quit the app when all windows are closed

    func applicationShouldTerminateAfterLastWindowClosed(_ theApplication: NSApplication) -> Bool {
        return true
    }

    // Check if there are changes that haven't been saved before allowing
    // the app to quit.

    @MainActor
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let state {
            if state.saveInProgress {
                state.addSheet(type: .savingUpdatesSheet)
                return .terminateCancel
            }

            if state.isDocumentEdited
               && state.tvm.images.contains(where: { $0.changed }) {
                state.confirmationMessage =
                    "If you quit GeoTag before saving changes the changes will be lost.  Are you sure you want to quit?"
                state.confirmationAction = terminateIgnoringEdits
                state.presentConfirmation = true
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    // passed as the action method to terminate confirmation view and
    // called when the user wants to terminate without saving changes.

    @MainActor
    func terminateIgnoringEdits() {
        state?.isDocumentEdited = false
        NSApp.terminate(NSApp)
    }

    // remove up the app sandbox documents directory before going away.
    // There is nothing in it that needs to be kept.

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
