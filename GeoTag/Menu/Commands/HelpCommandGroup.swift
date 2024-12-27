//
//  HelpCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
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
