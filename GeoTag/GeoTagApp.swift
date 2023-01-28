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
    let windowWidth = 1200.0
    let windowHeight = 900.0

    var body: some Scene {
        Window("GeoTag Version Five", id: "main") {
            ContentView()
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .background(WindowAccessor(window: $avm.mainWindow))
                .onAppear {
                    appDelegate.viewModel = avm
                }
                .environmentObject(avm)
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
            SettingsView(backupURL: avm.backupURL)
                .frame(width: 600.0, height: 550.0, alignment: .top)
                .environmentObject(avm)
        }
        .windowResizability(.contentSize)

    }
}

extension GeoTagApp {
    static var adjustTimeZone = "Change Time Zone"
    static var modifyDateTime = "Modify Image Date/Time"
    static var modifyLocation = "Modify Image Location"
}
