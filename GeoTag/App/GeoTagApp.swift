//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import AdjustTimeZoneView
import ExtendTimestampView
import RunLogView
import SwiftUI

@main
struct GeoTagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    @State var state = AppState()

    let windowWidth = 1000.0
    let windowHeight = 700.0

    var body: some Scene {
        Window("GeoTag Version Five", id: "main") {
            ContentView()
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .background(WindowAccessor(window: $state.mainWindow))
                .onAppear {
                    appDelegate.state = state
                }
                .environment(state)
        }
        .commands {
            NewItemCommands(state: state)
            SaveItemCommands(state: state)
            UndoRedoCommands(state: state)
            PasteboardCommands(state: state)
            ToolbarCommands(state: state)
            HelpCommands(state: state)
        }

        Window(GeoTagApp.adjustTimeZone, id: GeoTagApp.adjustTimeZone) {
            AdjustTimezoneView(timeZone: $state.timeZone)
                .frame(width: 500.0, height: 570.0)
                .environment(state)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Window(GeoTagApp.showRunLog, id: GeoTagApp.showRunLog) {
            RunLogView()
                .frame(width: 700, height: 500)
                .environment(state)
        }
        .windowResizability(.contentSize)
        .commandsRemoved()

        Settings {
            SettingsView()
                .frame(width: 600.0, height: 590.0, alignment: .top)
                .environment(state)
        }
        .windowResizability(.contentSize)

    }
}

// Window ids

extension GeoTagApp {
    static var adjustTimeZone = "Change Time Zone"
    static var showRunLog = "GeoTag Run/Debug Log"
}

// Text field focus. When non-nil a text field has focus.  Used to enable
// appropriate pasteboard actions for text fields.

extension FocusedValues {
    @Entry var textfieldFocused: String?
}
