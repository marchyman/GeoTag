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
            Button("Cut") { vm.selectedMenuAction = .cut }
                .keyboardShortcut("x")
                .disabled(vm.cutCopyDisabled())
            Button("Copy") { vm.selectedMenuAction = .copy }
                .keyboardShortcut("c")
                .disabled(vm.cutCopyDisabled())
            Button("Paste") { vm.selectedMenuAction = .paste }
                .keyboardShortcut("v")
                .disabled(vm.pasteDisabled())
            Button("Delete") { vm.selectedMenuAction = .delete }
                .keyboardShortcut(.delete, modifiers: EventModifiers())
                .disabled(vm.deleteDisabled())
            Button("Select All") { vm.selectedMenuAction = .selectAll }
                .keyboardShortcut("a")
                .disabled(vm.images.isEmpty)
        }
    }
}
