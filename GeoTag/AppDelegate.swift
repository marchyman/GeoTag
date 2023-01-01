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
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // things that can not (yet?) be done in SwiftUI (or can be done but
    // I don't know how so do it this way.

    func applicationDidFinishLaunching(_ notification: Notification) {
        // no tabbing in GeoTag
        NSWindow.allowsAutomaticWindowTabbing = false

        //  no need for the view menu
        if let mainMenu = NSApp.mainMenu {
            DispatchQueue.main.async {
                if let view = mainMenu.items.first(where: { $0.title == "View"}) {
                    mainMenu.removeItem(view);
                }
            }
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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
//        if saveOrDontSave() {
//            tableViewController.clear(self)
//            return .terminateNow
//        }
//        return .terminateCancel
        return .terminateNow
    }
}

