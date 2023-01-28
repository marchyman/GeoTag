//
//  SaveItemCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

// Add Save... and other menu, items

extension GeoTagApp {
    var saveItemCommandGroup: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save…") { avm.saveAction() }
                .keyboardShortcut("s")
                .disabled(avm.saveDisabled())

            Button("Discard changes") {
                ContentViewModel.shared.confirmationMessage = "Discarding all changes is not undoable.  Are you sure this is what you want to do?"
                ContentViewModel.shared.confirmationAction = avm.discardChangesAction
                ContentViewModel.shared.presentConfirmation = true
            }
            .disabled(avm.discardChangesDisabled())

            Button("Discard tracks") { avm.discardTracksAction() }
                .disabled(avm.discardTracksDisabled())

            Divider()
            
            Button("Clear Image List") { avm.clearImageListAction() }
                .keyboardShortcut("k")
                .disabled(avm.clearDisabled)
        }
    }
}
