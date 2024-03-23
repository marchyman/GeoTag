//
//  UndoRedoCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/7/23.
//

import SwiftUI

// Replace the undoRedo commands group

struct UndoRedoCommands: Commands {
    var state: AppState

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(state.undoManager.undoMenuItemTitle) { state.undoAction() }
                .keyboardShortcut("z")
                .disabled(state.undoDisabled)

            Button(state.undoManager.redoMenuItemTitle) { state.redoAction() }
                .keyboardShortcut("z", modifiers: [.shift, .command])
                .disabled(state.redoDisabled)
        }
    }
}
