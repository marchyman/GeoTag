//
//  NewItemCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Add a file open command in place of New...

struct NewItemCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { state.showOpenPanel() }
                .keyboardShortcut("o")
        }
    }
}
