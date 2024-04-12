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
    @State var state = AppState()
    @FocusedBinding(\.textfieldBinding) var textfieldBinding

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
            newItemCommandGroup
            saveItemCommandGroup
            undoRedoCommandGroup
            pasteBoardCommandGroup
            toolbarCommandGroup
            helpCommandGroup
        }

        Window(GeoTagApp.adjustTimeZone, id: GeoTagApp.adjustTimeZone) {
            AdjustTimezoneView()
                .frame(width: 500.0, height: 570.0)
                .environment(state)
        }
        .windowStyle(.hiddenTitleBar)
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
}

// Text field focus. When the bound value is true a text field
// has focus.  Used when processing pasteboard commands.

struct FocusedTextfield: FocusedValueKey {
    typealias Value = Binding<Bool?>
}

extension FocusedValues {
    var textfieldBinding: FocusedTextfield.Value? {
        get { self[FocusedTextfield.self] }
        set { self[FocusedTextfield.self] = newValue }
    }
}
