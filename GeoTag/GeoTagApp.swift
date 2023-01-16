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
    @StateObject var vm = ViewModel()
    let windowWidth = 1200.0
    let windowHeight = 900.0

    var body: some Scene {
        Window("GeoTag Version Five", id: "main") {
            ContentView()
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .background(WindowAccessor(window: $vm.window))
                .environmentObject(vm)
                .onAppear {
                    appDelegate.viewModel = vm
                }
        }
        .commands {
            newItemCommandGroup
            saveItemCommandGroup
            undoRedoCommandGroup
            pasteBoardCommandGroup
            helpCommandGroup
        }

        Window(GeoTagApp.adjustTimeZone, id: GeoTagApp.adjustTimeZone) {
            AdjustTimezoneView()
                .frame(width: 500.0, height: 570.0)
                .environmentObject(vm)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Window(GeoTagApp.modifyDateTime, id: GeoTagApp.modifyDateTime) {
            ModifyDateTimeView()
                .frame(width: 450.0, height: 250.0, alignment: .top)
                .environmentObject(vm)
       }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Window(GeoTagApp.modifyLocation, id: GeoTagApp.modifyLocation) {
            ModifyLocationView()
                .frame(width: 450.0, height: 250.0, alignment: .top)
                .environmentObject(vm)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()

        Settings {
            SettingsView()
                .frame(width: 600.0, height: 550.0, alignment: .top)
                .environmentObject(vm)
        }
        .windowResizability(.contentSize)

    }
}

extension GeoTagApp {
    static var adjustTimeZone = "Change Time Zone"
    static var modifyDateTime = "Modify Image Date/Time"
    static var modifyLocation = "Modify Image Location"
}
