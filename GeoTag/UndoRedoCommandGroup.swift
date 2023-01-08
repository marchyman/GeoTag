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
            Button("Undo") { vm.setMenuAction(for: .undo) }
                .keyboardShortcut("z")
                .disabled(vm.undoDisabled)
            Button("Redo") { vm.setMenuAction(for: .redo) }
                .keyboardShortcut("z", modifiers: [.shift, .command])
                .disabled(vm.redoDisabled)
        }
    }
}
