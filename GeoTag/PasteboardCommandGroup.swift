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
            Group {
                Button("Cut") { vm.cutAction() }
                    .keyboardShortcut("x")
                    .disabled(vm.cutCopyDisabled())

                Button("Copy") { vm.copyAction() }
                    .keyboardShortcut("c")
                    .disabled(vm.cutCopyDisabled())

                Button("Paste") { vm.pasteAction() }
                    .keyboardShortcut("v")
                    .disabled(vm.pasteDisabled())

                Button("Delete") { vm.deleteAction() }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(vm.deleteDisabled())

                Button("Select All") { vm.selectAllAction() }
                    .keyboardShortcut("a")
                    .disabled(vm.selectAllDisabled())
            }

            Divider()

            Group {
                Button("Show In Finder") { vm.showInFinderAction() }
                    .disabled(vm.showInFinderDisabled())

                Button("Locn From Track") { vm.locnFromTrackAction() }
                    .keyboardShortcut("l")
                    .disabled(vm.locnFromTrackDisabled())
                
                Button("Specify Time Zone…") {
                    ContentViewModel.shared.changeTimeZoneWindow.toggle()
                }
            }
        }
    }
}
