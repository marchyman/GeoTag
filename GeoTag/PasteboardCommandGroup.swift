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
                .disabled(appState.selectedIndex == nil)
            Button("Copy") { appState.selectedMenuAction = .copy }
                .keyboardShortcut("c")
                .disabled(appState.selectedIndex == nil)
            Button("Paste") { appState.selectedMenuAction = .paste }
                .keyboardShortcut("v")
                .disabled(appState.selectedIndex == nil)
            Button("Delete") { appState.selectedMenuAction = .delete }
                .keyboardShortcut(.delete)
                .disabled(appState.selectedIndex == nil)
            Button("Select All") { appState.selectedMenuAction = .selectAll }
                .keyboardShortcut("a")
                .disabled(appState.images.isEmpty)
        }
    }
}
