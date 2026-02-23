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
                Button("Cut", systemImage: "scissors") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.cut(_:)),
                                         to: nil, from: nil)
                    } else {
                        copy()
                        store.send(.deleteRequest)
                    }
                }
                .keyboardShortcut("x")
                .disabled(cutCopyDisabled())

                Button("Copy", systemImage: "document.on.document") {
                    copy()
                }
                .keyboardShortcut("c")
                .disabled(cutCopyDisabled())

                Button("Paste", systemImage: "document.on.clipboard") {
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
                                    store.send(.addressChanged(selected, address),
                                               undoable: false)
                                }
                            }
                        }
                    }
                }
                .keyboardShortcut("v")
                .disabled(pasteDisabled())

                Button("Delete", systemImage: "trash") {
                    if isFocused(textfieldFocused) {
                        NSApp.sendAction(#selector(NSText.delete(_:)),
                                         to: nil, from: nil)
                    } else {
                        store.send(.deleteRequest)
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(deleteDisabled())

                Button("Select All", systemImage: "character.textbox") {
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
                Button("Find (map)...") {
                    store.send(.findInMap(true), undoable: false)
                }
                .keyboardShortcut("f")
            }

            Divider()

            Group {
                Button("Show In Finder") {
                    // this command does not update state and therefore
                    // need not go through the reducer.
                    showInFinder()
                }
                .disabled(showInFinderDisabled())

                Button("Locn From Track") {
                    LocationHelper.locationFromTrack(store,
                                                     extendedTime: extendedTime)
                }
                .keyboardShortcut("l")
                .disabled(locnFromTrackDisabled())

                Button("Specify Time Zone…") {
                    store.send(.changeTimeZone, undoable: false)
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

    private func showInFinderDisabled() -> Bool {
        if let mostSelected = store.mostSelected {
            switch store[mostSelected].metadata.source {
            case .image, .xmp:
                return false
            default:
                break
            }
        }
        return true
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

// copy the selected item into the pasteboard.  Does not change program state

extension PasteboardCommands {
    private func copy() {
        if isFocused(textfieldFocused) {
            NSApp.sendAction(#selector(NSText.copy(_:)),
                to: nil, from: nil)
        } else if let id = store.mostSelected {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(store[id].stringRepresentation,
                         forType: .string)
        }
    }
}

// show the selected items in the finder.  Does not change program state

extension PasteboardCommands {
    private func showInFinder() {
        var urls: [URL] = []

        for id in store.selection {
            switch store[id].metadata.source {
            case .image(let url), .xmp(let url):
                urls.append(url)
            default:
                // not where the finder can see it
                break
            }
        }
        if !urls.isEmpty {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
        }
    }
}
