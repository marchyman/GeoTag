//
//  UndoRedoCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/7/23.
//

import SwiftUI

// Replace the undoRedo commands group

extension GeoTagApp {
    var undoRedoCommandGroup: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(avm.undoManager.undoMenuItemTitle) { avm.undoAction() }
                .keyboardShortcut("z")
                .disabled(avm.undoDisabled)
            
            Button(avm.undoManager.redoMenuItemTitle) { avm.redoAction() }
                .keyboardShortcut("z", modifiers: [.shift, .command])
                .disabled(avm.redoDisabled)
        }
    }
}
