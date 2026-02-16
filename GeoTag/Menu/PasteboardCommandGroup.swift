// import MapAndSearchViews
import AppKit
import ImageData
import SwiftUI
import UDF

// Replace the pasteboard commands group

struct PasteboardCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>
    @FocusedValue(\.textfieldFocused) var textfieldFocused
    @AppStorage(SettingsView.extendedTimeKey) var extendedTime = 120.0

    var body: some Commands {
         CommandGroup(replacing: .pasteboard) {
            Group {
                Button("Cut") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.cut(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.cutRequest)
                    }
                }
                .keyboardShortcut("x")
                .disabled(cutCopyDisabled())

                Button("Copy") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.copy(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.copyRequest)
                    }
                }
                .keyboardShortcut("c")
                .disabled(cutCopyDisabled())

                Button("Paste") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.paste(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.pasteRequest) {
                            // remember the current selection
                            guard let id = store.mostSelected else { return }
                            let selected = store.selection
                            Task {
                                let address =
                                await ReverseLocationFinder.reverseGeocode(store: store,
                                                                           id: id)
                                if let address {
                                    store.send(.addressChanged(selected, address))
                                    store.discardUndo()
                                }
                            }
                        }
                    }
                }
                .keyboardShortcut("v")
                .disabled(pasteDisabled())

                Button("Delete") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.delete(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.deleteRequest)
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(deleteDisabled())

                Button("Select All") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.selectAll(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.selectAllRequest)
                    }
                }
                .keyboardShortcut("a")
                .disabled(selectAllDisabled())
            }

            Divider()

            Group {
                Button("Find") {
                    // TODO: state.masData.searchBarActive = true
                }
                .keyboardShortcut("f")
            }

            Divider()

            Group {
                Button("Show In Finder") {
                    store.send(.showInFinder)
                    store.discardUndo()
                }
                .disabled(store.mostSelected == nil)

                Button("Locn From Track") {
                    // TODO: store.send(.locnFromTrack(extendedTime)
                }
                .keyboardShortcut("l")
                .disabled(locnFromTrackDisabled())

                Button("Specify Time Zone…") {
                    store.send(.changeTimeZone)
                    store.discardUndo()
                }
            }
        }
    }
}

// Helper functions: determine if command should be disabled

extension PasteboardCommands {

    private func cutCopyDisabled() -> Bool {
        if isFocused(textfieldFocused) {
            return false
        }
        if let id = store.mostSelected, store[id].metadata.location != nil {
            return false
        }
        return true
    }

    private func pasteDisabled() -> Bool {
        if isFocused(textfieldFocused) {
            return false
        }
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: .string),
           ImageData.decodeStringRep(value: pasteVal) != nil,
           store.mostSelected != nil {
            return false
        }
        return true
    }

    private func deleteDisabled() -> Bool {
        if isFocused(textfieldFocused) {
            return false
        }
        return store.selection.allSatisfy { store[$0].metadata.location == nil }
    }

    private func selectAllDisabled() -> Bool {
        if isFocused(textfieldFocused) {
            return false
        }
        return store.imageData.isEmpty
    }

    private func locnFromTrackDisabled() -> Bool {
        if store.gpxTracks.count > 0 {
            if let id = store.mostSelected, store[id].updatable {
                return false
            }
        }
        return true
    }

    // return true if a search active or a textField is focused.
    private func isFocused(_ textField: String?) -> Bool {
        return store.searchActive || textField != nil
    }
}
