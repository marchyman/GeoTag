//
//  UndoRedoAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/7/23.
//

import Foundation

extension ViewModel {
    // return true if the undo menu option should be disabled.

    var undoDisabled: Bool {
        guard let keyWindow = window?.isKeyWindow, keyWindow else { return true }
        return !undoManager.canUndo
    }

    // return true if the red menu option should be disabled.

    var redoDisabled: Bool {
        guard let keyWindow = window?.isKeyWindow, keyWindow else { return true }
        return !undoManager.canRedo
    }

    func undoAction() {
        if undoManager.canUndo {
            undoManager.undo()
        }
    }

    func redoAction() {
        if undoManager.canRedo {
            undoManager.redo()
        }
    }
}
