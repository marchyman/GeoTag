//
//  GeoTagApp.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/9/22.
//

import SwiftUI

@main
struct GeoTagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    showOpenPanel(appState)
                }.keyboardShortcut("o")
            }
        }
    }
}

/// GeoTag AppDelegate Class
///
/// App Delegate needed to get some desired behaviors such as terminate app when window closed
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // instantiate openundomanager when needed
    lazy var undoManager = UndoManager()

    // things that can not (yet?) be done in SwiftUI
    //
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

    // this delegate function is not being called.  I do not know why.
    //
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        print("flag is \(flag)")
        return true
    }

    // no window -- terminate app
    func applicationShouldTerminateAfterLastWindowClosed(
        _ theApplication: NSApplication
    ) -> Bool {
        return true
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
//        if saveOrDontSave() {
//            tableViewController.clear(self)
//            return .terminateNow
//        }
//        return .terminateCancel
        return .terminateNow
    }
}
