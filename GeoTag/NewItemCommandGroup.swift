//
//  NewItemCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

// Add a file open command in place of New...

extension GeoTagApp {
    var newItemCommandGroup: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…") { avm.showOpenPanel() }
                .keyboardShortcut("o")
        }
    }
}

