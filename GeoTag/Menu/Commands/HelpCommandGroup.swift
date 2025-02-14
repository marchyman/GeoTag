//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// Add a help button that will link to the on line help pages.

struct HelpCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Link("GeoTag 5 Help…",
                destination: URL(string: "https://www.snafu.org/GeoTag/GeoTag5Help/")!)
            Divider()
            Link("Report a bug…",
                 destination: URL(string: "https://github.com/marchyman/GeoTag/issues")!)
            Button("Show log…") {
                state.showLogWindow.toggle()
            }
        }
    }
}
