//
//  HelpCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import SwiftUI

// Replace the help button with something a button that will link to
// on line help pages.

extension GeoTagApp {
    var helpCommandGroup: some Commands {
        CommandGroup(replacing: .help) {
            Button("GeoTag 5 Help...") {
                let helpPagePath = "https://www.snafu.org/GeoTag/GeoTag5Help/"
                let helpPage = URL(string: helpPagePath)!
                NSWorkspace.shared.open(helpPage)
            }
        }
    }
}

