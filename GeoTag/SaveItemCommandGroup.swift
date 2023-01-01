//
//  SaveItemCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

// Add a file open command in place of New...

extension GeoTagApp {
    var saveItemCommandGroup: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save…") { vm.selectedMenuAction = .save }
                .keyboardShortcut("s")
                .disabled(vm.saveDisabled())
            Button("Discard changes") { vm.selectedMenuAction = .discardChanges }
                .disabled(vm.discardChangesDisabled())
            Button("Discard tracks") { vm.selectedMenuAction = .discardTracks }
                .disabled(vm.discardTracksDisabled())
            Divider()
            Button("Clear Image List") { vm.selectedMenuAction = .clearList }
                .keyboardShortcut("k")
                .disabled(vm.clearDisabled)
        }
    }
}
