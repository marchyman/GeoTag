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
                Button("Cut") { setPastboardItemAction(.cut) }
                    .keyboardShortcut("x")
                    .disabled(vm.cutCopyDisabled())

                Button("Copy") { setPastboardItemAction(.copy) }
                    .keyboardShortcut("c")
                    .disabled(vm.cutCopyDisabled())

                Button("Paste") { setPastboardItemAction(.paste) }
                    .keyboardShortcut("v")
                    .disabled(vm.pasteDisabled())

                Button("Delete") { setPastboardItemAction(.delete) }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(vm.deleteDisabled())

                Button("Select All") { setPastboardItemAction(.selectAll) }
                    .keyboardShortcut("a")
                    .disabled(vm.selectAllDisabled())
            }

            Divider()

            Group {
                Button("Show In Finder") { setPastboardItemAction(.showInFinder) }
                    .disabled(vm.showInFinderDisabled())

                Button("Locn From Track") { setPastboardItemAction(.locnFromTrack) }
                    .keyboardShortcut("l")
                    .disabled(vm.locnFromTrackDisabled())
                
                Button("Specify Time Zone…") { setPastboardItemAction(.adjustTimeZone) }
            }
        }
    }

    func setPastboardItemAction(_ action: AppViewModel.MenuAction) {
        vm.setMenuAction(for: action)
    }
}
