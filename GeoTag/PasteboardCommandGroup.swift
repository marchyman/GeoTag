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
                Button("Cut") { state.cutAction(textfield: textfieldBinding) }
                    .keyboardShortcut("x")
                    .disabled(state.cutCopyDisabled())

                Button("Copy") { state.copyAction(textfield: textfieldBinding) }
                    .keyboardShortcut("c")
                    .disabled(state.cutCopyDisabled())

                Button("Paste") { state.pasteAction(textfield: textfieldBinding) }
                    .keyboardShortcut("v")
                    .disabled(state.pasteDisabled(textfield: textfieldBinding))

                Button("Delete") { state.deleteAction(textfield: textfieldBinding) }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(state.deleteDisabled())

                Button("Select All") { state.selectAllAction(textfield: textfieldBinding) }
                    .keyboardShortcut("a")
                    .disabled(state.selectAllDisabled())
            }

            Divider()

            Group {
                Button("Show In Finder") { state.showInFinderAction() }
                    .disabled(state.showInFinderDisabled())

                Button("Locn From Track") { state.locnFromTrackAction() }
                    .keyboardShortcut("l")
                    .disabled(state.locnFromTrackDisabled())

                Button("Specify Time Zone…") {
                    state.changeTimeZoneWindow.toggle()
                }
            }
        }
    }
}
