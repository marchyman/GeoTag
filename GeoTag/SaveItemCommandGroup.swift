//
//  SaveItemCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

// Add Save... and other menu, items

struct SaveItemCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save…") { state.saveAction() }
                .keyboardShortcut("s")
                .disabled(state.saveDisabled())

            Button("Discard changes") {
                state.confirmationMessage =
                    "Discarding all changes is not undoable.  Are you sure this is what you want to do?"
                state.confirmationAction = state.discardChangesAction
                state.presentConfirmation = true
            }
            .disabled(state.discardChangesDisabled())

            Button("Discard tracks") { state.discardTracksAction() }
                .disabled(state.discardTracksDisabled())

            Divider()

            Button("Clear Image List") { state.clearImageListAction() }
                .keyboardShortcut("k")
                .disabled(state.clearDisabled)
        }
    }
}
