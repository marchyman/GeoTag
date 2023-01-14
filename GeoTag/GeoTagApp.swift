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

    var body: some Scene {
        WindowGroup("GeoTag Version Five") {
            ContentView()
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
        .windowResizability(.contentSize)

        Window(GeoTagApp.modifyDateTime, id: GeoTagApp.modifyDateTime) {
            ModifyDateTimeView()
                .environmentObject(vm)
       }

        Window(GeoTagApp.modifyLocation, id: GeoTagApp.modifyLocation) {
            ModifyLocationView()
                .environmentObject(vm)
        }

        Settings {
            SettingsView()
                .frame(width: 600.0, height: 550.0)
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
