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

    // macOS 14.3 and later: state undo values are never checked.  As a result
    // undo/redu are always disabled.  Comment out the check and live with
    // menu item titles that do not change

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(state.undoManager.undoMenuItemTitle) { state.undoAction() }
                .keyboardShortcut("z")
                // .disabled(state.undoDisabled)

            Button(state.undoManager.redoMenuItemTitle) { state.redoAction() }
                .keyboardShortcut("z", modifiers: [.shift, .command])
                // .disabled(state.redoDisabled)
        }
    }
}
