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
    @StateObject var vm = AppState()

    var body: some Scene {
        WindowGroup("GeoTag Version Five") {
            ContentView()
                .background(WindowAccessor(window: $vm.window))
                .environmentObject(vm)
        }
        .commands {
            newItemCommandGroup
            pasteBoardCommandGroup
            helpCommandGroup
        }

        Settings {
            SettingsView()
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

    // Called when window that was hidden is now visible
    //
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        // print("flag is \(flag)")
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

// Access to main window
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
