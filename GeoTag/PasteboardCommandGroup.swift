//
//  PasteboardCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/23/22.
//

import SwiftUI

// Replace the pasteboard commands group
extension GeoTagApp {
    var pasteBoardCommandGroup: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Button("Cut") { appState.selectedMenuAction = .cut }
                .keyboardShortcut("x")
                .disabled(!appState.canCutOrCopy)
            Button("Copy") { appState.selectedMenuAction = .copy }
                .keyboardShortcut("c")
                .disabled(!appState.canCutOrCopy)
            Button("Paste") { appState.selectedMenuAction = .paste }
                .keyboardShortcut("v")
                .disabled(!appState.isSelectedImageValid)
            Button("Delete") { appState.selectedMenuAction = .delete }
                .keyboardShortcut(.delete, modifiers: EventModifiers())
                .disabled(!appState.canDelete)
            Button("Select All") { appState.selectedMenuAction = .selectAll }
                .keyboardShortcut("a")
                .disabled(appState.images.isEmpty)
        }
    }
}
