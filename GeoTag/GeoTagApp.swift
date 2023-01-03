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
            saveItemCommandGroup
            pasteBoardCommandGroup
            helpCommandGroup
        }

        Settings {
            SettingsView()
                .environmentObject(vm)
        }

    }
}

