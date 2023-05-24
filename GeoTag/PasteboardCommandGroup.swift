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
                Button("Cut") { avm.cutAction() }
                    .keyboardShortcut("x")
                    .disabled(avm.cutCopyDisabled())

                Button("Copy") { avm.copyAction() }
                    .keyboardShortcut("c")
                    .disabled(avm.cutCopyDisabled())

                Button("Paste") { avm.pasteAction() }
                    .keyboardShortcut("v")
                    .disabled(avm.pasteDisabled())

                Button("Delete") { avm.deleteAction() }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(avm.deleteDisabled())

                Button("Select All") { avm.selectAllAction() }
                    .keyboardShortcut("a")
                    .disabled(avm.selectAllDisabled())
            }

            Divider()

            Group {
                Button("Show In Finder") { avm.showInFinderAction() }
                    .disabled(avm.showInFinderDisabled())

                Button("Locn From Track") { avm.locnFromTrackAction() }
                    .keyboardShortcut("l")
                    .disabled(avm.locnFromTrackDisabled())

                Button("Specify Time Zone…") {
                    ContentViewModel.shared.changeTimeZoneWindow.toggle()
                }
            }
        }
    }
}
