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
            Button("Save…") { setSaveItemAction(.save) }
                .keyboardShortcut("s")
                .disabled(vm.saveDisabled())
            Button("Discard changes") {
                vm.confirmationAction = vm.discardChangesAction
                vm.confirmationMessage = "Discarding all location changes is not undoable.  Are you sure this is what you want to do?"
                vm.presentConfirmation = true
            }
            .disabled(vm.discardChangesDisabled())
            Button("Discard tracks") { setSaveItemAction(.discardTracks) }
                .disabled(vm.discardTracksDisabled())
            Divider()
            Button("Clear Image List") { setSaveItemAction(.clearList) }
                .keyboardShortcut("k")
                .disabled(vm.clearDisabled)
        }
    }

    func setSaveItemAction(_ action: ViewModel.MenuAction) {
        vm.setMenuAction(for: action)
    }
}
