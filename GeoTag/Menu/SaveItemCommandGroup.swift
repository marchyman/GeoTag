import SwiftUI
import UDF

// Add Save... and other menu, items

struct SaveItemCommands: Commands {
    var store: Store<GeoTagState, GeoTagEvent>

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Save…", systemImage: "square.and.arrow.down.on.square") {
                store.send(.saveRequest, undoable: false) {
                    // capture the data needed to update images
                    let libraryImages =
                        Dictionary(uniqueKeysWithValues: store.libraryImages.map {
                            (store.imageData[$0].id, store.imageData[$0].metadata)
                        })
                    print("libraryImages: \(libraryImages)")
                    let fileImages =
                        Dictionary(uniqueKeysWithValues: store.fileImages.map {
                            (store.imageData[$0].id, store.imageData[$0].metadata)
                        })
                    print("fileImages: \(fileImages)")
                    let xmpImages =
                        Dictionary(uniqueKeysWithValues: store.xmpImages.map {
                            (store.imageData[$0].id, store.imageData[$0].metadata)
                        })
                    print("xmpImages: \(xmpImages)")
                }
                store.discardAllUndo()
            }
            .keyboardShortcut("s")
            .disabled(saveDisabled())

            Button("Discard changes", systemImage: "mappin.slash") {
                store.send(.discardChangesRequest,
                           description: "discard changes")
            }
            .disabled(discardChangesDisabled())

            Button("Discard tracks",
                   systemImage: "stroke.line.diagonal.slash") {
                store.send(.discardTracksRequest,
                           description: "discard tracks")
            }
            .disabled(discardTracksDisabled())

            Divider()

            Button("Clear Image List", systemImage: "rectangle.stack.slash") {
                store.send(.clearImagesRequest,
                           description: "clear image list")
            }
            .keyboardShortcut("k")
            .disabled(clearDisabled())
        }
    }
}

extension SaveItemCommands {
    private func saveDisabled() -> Bool {
        return store.saveInProgress || !store.unsavedChanges
    }

    private func discardChangesDisabled() -> Bool {
        return !store.unsavedChanges
    }

    private func discardTracksDisabled() -> Bool {
        return store.gpxTracks.isEmpty
    }

    private func clearDisabled() -> Bool {
        return store.imageData.isEmpty || store.unsavedChanges
    }
}
