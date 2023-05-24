//
//  HelpCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import SwiftUI

// Add a help button that will link to the on line help pages.

extension GeoTagApp {
    var helpCommandGroup: some Commands {
        CommandGroup(replacing: .help) {
            Button("GeoTag 5 Help…") {
                let helpPagePath = "https://www.snafu.org/GeoTag/GeoTag5Help/"
                let helpPage = URL(string: helpPagePath)!
                NSWorkspace.shared.open(helpPage)
            }
            Divider()
            Button("Report a bug…") {
                let bugReportPath = "https://github.com/marchyman/GeoTag/issues"
                let bugReportPage = URL(string: bugReportPath)!
                NSWorkspace.shared.open(bugReportPage)
            }
        }
    }
}
