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
        }
        .commands {
            newItemCommandGroup
            saveItemCommandGroup
            pasteBoardCommandGroup
            helpCommandGroup
        }

        Window(GeoTagApp.adjustTimeZone, id: GeoTagApp.adjustTimeZone) {
            AdjustTimezoneView()
                .environmentObject(vm)
        }

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
                .environmentObject(vm)
        }

    }
}

extension GeoTagApp {
    static var adjustTimeZone = "Adjust Time Zone"
    static var modifyDateTime = "Modify Image Date/Time"
    static var modifyLocation = "Modify Image Location"
}
