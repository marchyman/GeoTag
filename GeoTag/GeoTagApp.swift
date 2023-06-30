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
    @StateObject var avm = AppViewModel()
    @FocusedBinding(\.textfieldBinding) var textfieldBinding

    let windowWidth = 1200.0
    let windowHeight = 900.0

    var body: some Scene {
        Window("GeoTag Version Five", id: "main") {
            ContentView()
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .background(WindowAccessor(window: $avm.mainWindow))
                .onAppear {
                    appDelegate.avm = avm
                }
                .environmentObject(avm)
                .environment(ContentViewModel.shared)
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
                .environmentObject(avm)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Settings {
            SettingsView()
                .frame(width: 600.0, height: 590.0, alignment: .top)
                .environmentObject(avm)
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
    typealias Value = Binding<Double?>
}

extension FocusedValues {
    var textfieldBinding: FocusedTextfield.Value? {
        get { self[FocusedTextfield.self] }
        set { self[FocusedTextfield.self] = newValue }
    }
}
