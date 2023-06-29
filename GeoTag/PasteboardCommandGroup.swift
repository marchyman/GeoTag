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
                Button("Cut") { avm.cutAction(textfield: textfieldBinding) }
                    .keyboardShortcut("x")
                    .disabled(avm.cutCopyDisabled())

                Button("Copy") { avm.copyAction(textfield: textfieldBinding) }
                    .keyboardShortcut("c")
                    .disabled(avm.cutCopyDisabled())

                Button("Paste") { avm.pasteAction(textfield: textfieldBinding) }
                    .keyboardShortcut("v")
                    .disabled(avm.pasteDisabled(textfield: textfieldBinding))

                Button("Delete") { avm.deleteAction(textfield: textfieldBinding) }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(avm.deleteDisabled())

                Button("Select All") { avm.selectAllAction(textfield: textfieldBinding) }
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
