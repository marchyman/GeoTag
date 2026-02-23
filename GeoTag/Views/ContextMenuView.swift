import ImageData
import SwiftUI
import UDF

// Duplicates many of the menu commands

struct ContextMenuView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store
    @AppStorage(SettingsView.extendedTimeKey) var extendedTime = 120.0

    let context: ImageData.ID?
    @Binding var inspectorPresented: Bool

    var body: some View {
        Group {
            Button("Edit…", systemImage: "pencil") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                inspectorPresented.toggle()
            }
            .disabled(context == nil && store.mostSelected == nil)
        }

        Divider()

        Group {
            Button("Cut", systemImage: "scissors") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                if let id = store.mostSelected {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(store[id].stringRepresentation,
                                 forType: .string)
                    store.send(.deleteRequest)
                }
            }
            .disabled(nothingToEdit(context: context))

            Button("Copy", systemImage: "document.on.document") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                if let id = store.mostSelected {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(store[id].stringRepresentation,
                                 forType: .string)
                }
            }
            .disabled(nothingToEdit(context: context))

             Button("Paste", systemImage: "document.on.clipboard") {
                if let context {
                     store.send(.selectionChanged([context]), undoable: false)
                }
                if let id = store.mostSelected {
                    store.send(.pasteRequest) {
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
             .disabled(pasteDisabled(context: context))

            Button("Delete", systemImage: "trash") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                store.send(.deleteRequest)
            }
            .disabled(nothingToEdit(context: context))
        }

        Divider()

        Group {
            Button("Show In Finder") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                showInFinder()
            }
            .disabled(context == nil && store.mostSelected == nil)

            Button("Locn From Track") {
                if let context {
                    store.send(.selectionChanged([context]), undoable: false)
                }
                LocationHelper.locationFromTrack(store,
                                                 extendedTime: extendedTime)

            }
            .disabled(store.gpxTracks.isEmpty ||
                      (context == nil && store.mostSelected == nil))
        }

        Divider()

        Button("Clear Image List") {
            store.send(.clearImagesRequest,
                       description: "clear image list")
        }
        .disabled(store.imageData.isEmpty || store.unsavedChanges)
    }
}

extension ContextMenuView {
    private func nothingToEdit(context: ImageData.ID?) -> Bool {
        if let context {
            return store[context].metadata.location == nil
        }
        if let id = store.mostSelected {
            return store[id].metadata.location == nil
        }
        return true
    }

    // must have paste data in teh appropriate form and either
    // context or mostSelected for paste to be enabled.

    private func pasteDisabled(context: ImageData.ID?) -> Bool {
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: .string),
           ImageData.decodeStringRep(value: pasteVal) != nil,
           context != nil || store.mostSelected != nil {
            return false
        }
        return true
    }

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

#Preview {
    @Previewable @State var toggle = false
    ContextMenuView(context: nil,
                    inspectorPresented: $toggle)
        .environment(Store(initialState: GeoTagState(),
                           reduce: GeoTagReducer()))
}
