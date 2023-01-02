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
                    .disabled(vm.images.isEmpty)
            }
            Divider()
            Group {
                Button("Show In Finder") { setPastboardItemAction(.showInFinder) }
                    .disabled(vm.showInFinderDisabled())
//                Button("Interpolate") { }
//                    .disabled(true)
                Button("Locn from track") { setPastboardItemAction(.locnFromTrack) }
                Button("Adjust Time Zone…") { setPastboardItemAction(.adjustTimeZone) }
                Button("Modify Date/Time…") { setPastboardItemAction(.modifyDateTime) }
                Button("Modify Location…") { setPastboardItemAction(.modifyLocation) }
            }
        }
    }

    func setPastboardItemAction(_ action: AppState.MenuAction) {
        vm.menuContext = nil
        vm.selectedMenuAction = action
    }
}
