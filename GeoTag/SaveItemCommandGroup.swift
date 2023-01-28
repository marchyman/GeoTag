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
            Button("Save…") { setSaveItemAction(.save) }
                .keyboardShortcut("s")
                .disabled(vm.saveDisabled())

            Button("Discard changes") {
                ContentViewModel.shared.confirmationMessage = "Discarding all changes is not undoable.  Are you sure this is what you want to do?"
                ContentViewModel.shared.confirmationAction = vm.discardChangesAction
                ContentViewModel.shared.presentConfirmation = true
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

    func setSaveItemAction(_ action: AppViewModel.MenuAction) {
        vm.setMenuAction(for: action)
    }
}
