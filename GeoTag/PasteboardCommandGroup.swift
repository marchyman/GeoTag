//
//  PasteboardCommandGroup.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/23/22.
//

import SwiftUI

// Replace the pasteboard commands group

struct PasteboardCommands: Commands {
    var state: AppState
    @FocusedValue(\.textfieldFocused) var textfieldFocused

    @MainActor
    var body: some Commands {
        CommandGroup(replacing: .pasteboard) {
            Group {
                Button("Cut") {
                    state.cutAction(textfield: textfieldFocused)
                }
                .keyboardShortcut("x")
                .disabled(state.cutCopyDisabled(textfield: textfieldFocused))

                Button("Copy") {
                    state.copyAction(textfield: textfieldFocused)
                }
                .keyboardShortcut("c")
                .disabled(state.cutCopyDisabled(textfield: textfieldFocused))

                Button("Paste") {
                    state.pasteAction(textfield: textfieldFocused)
                }
                .keyboardShortcut("v")
                .disabled(state.pasteDisabled(textfield: textfieldFocused))

                Button("Delete") {
                    state.deleteAction(textfield: textfieldFocused)
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(state.deleteDisabled(textfield: textfieldFocused))

                Button("Select All") {
                    state.selectAllAction(textfield: textfieldFocused)
                }
                .keyboardShortcut("a")
                .disabled(state.selectAllDisabled(textfield: textfieldFocused))
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
