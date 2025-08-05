//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapAndSearchViews
import SwiftUI

// Replace the toolbar commands group.  The command has nothing to do with a
// toolbar, but it's in the View menu which is where I want it.

struct ToolbarCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(replacing: .toolbar) {
            Section {
                Button {
                    @AppStorage(AppSettings.hideInvalidImagesKey)
                    var hideInvalidImages = false

                    hideInvalidImages.toggle()
                } label: {
                    ShowHidePinView()
                }
                .keyboardShortcut("d")

                PinOptionView(masData: state.masData)

                Button {
                    @AppStorage(AppSettings.alternateLayoutKey)
                    var alternateLayout = false

                    alternateLayout.toggle()
                } label: {
                    AlternateLayoutOptionView()
                }
            }

        }
    }
}

struct ShowHidePinView: View {
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

    var body: some View {
        Text("\(hideInvalidImages ? "Show" : "Hide") Disabled Files")
    }
}

struct PinOptionView: View {
    @Bindable var masData: MapAndSearchData

    var body: some View {
        Picker("Pin view options…", selection: $masData.showOtherPins) {
            Text("Show pins for all selected items").tag(true)
            Text("Show pin for most selected item").tag(false)
        }
        .pickerStyle(.menu)
    }
}

struct AlternateLayoutOptionView: View {
    @AppStorage(AppSettings.alternateLayoutKey) var alternateLayout = false

    var body: some View {
        Text("\(alternateLayout ? "Normal" : "Alternate") Layout")
    }
}
