import ImageData
import Imagetool
import Metadata
import Phototool
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
                    let fileImages =
                        Dictionary(uniqueKeysWithValues: store.fileImages.map {
                            (store.imageData[$0].id, store.imageData[$0].metadata)
                        })
                    let xmpImages =
                        Dictionary(uniqueKeysWithValues: store.xmpImages.map {
                            (store.imageData[$0].id, store.imageData[$0].metadata)
                        })
                    Task {
                        async let libUpdated = saveToLibrary(libraryImages)
                        async let imgUpdated = saveToImage(fileImages)
                        async let xmpUpdated = saveToXmp(xmpImages)

                        let ok = await [libUpdated, imgUpdated, xmpUpdated]
                        store.send(.saveComplete(ok.allSatisfy { $0 == true }),
                                   undoable: false)
                    }
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

// save changes functions triggered by a save request

extension SaveItemCommands {

    func saveToLibrary(_ info: [ImageData.ID: Metadata]) async -> Bool {
        var updateOK = true
        for (id, metadata) in info {
            if case .photos(_, let asset) = metadata.source, let asset {
                let timestamp = metadata.date()
                let location = metadata.clLocation(nil)
                let ok = await Phototool.update(timestamp: timestamp,
                                                location: location,
                                                for: asset)
                if ok {
                    store.send(.imageSaved(id, metadata), undoable: false)
                } else {
                    updateOK = false
                }
            }
        }
        return updateOK
    }

    // pass copy if MainActor related data to a nonisolated function
    // that performs updates in parallel

    func saveToImage(_ info: [ImageData.ID: Metadata]) async -> Bool {
        @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
        @AppStorage(SettingsView.addTagsKey) var addTags = false
        @AppStorage(SettingsView.finderTagKey) var finderTag = "GeoTag"
        @AppStorage(SettingsView.createSidecarFilesKey) var createSidecarFiles = false

        // make sure there is something to do
        guard !info.isEmpty else { return true }

        // make sure backups are disabled or we have a backup folder
        guard doNotBackup || store.backupURL != nil else {
            store.send(.noBackupNotice, undoable: false)
            // return true as we've already notified the user that
            // nothing was saved
            return true
        }
        let backupURL = doNotBackup ? nil : store.backupURL
        let tagName = finderTag.isEmpty ? "GeoTag" : finderTag
        return await saveToImageTasks(info, createSidecarFiles,
                                      backupURL, addTags, tagName)
    }

    // Update the items in the info dictionary in a task group

    nonisolated func saveToImageTasks(_ info: [ImageData.ID: Metadata],
                                      _ createSidecarFiles: Bool,
                                      _ backupURL: URL?,
                                      _ tagFiles: Bool,
                                      _ tagName: String) async -> Bool {
        var updateOK = true
        struct TaskInfo {
            let id: ImageData.ID
            let metadata: Metadata
            let sidecarCreated: Bool
            let status: Bool
        }

        await withTaskGroup(of: TaskInfo.self) { group in
            for (id, metadata) in info {
                group.addTask {
                    guard case .image(let imageURL) = metadata.source else {
                        return TaskInfo(id: id, metadata: metadata,
                                        sidecarCreated: false, status: false)
                    }

                    var sidecarCreated = false
                    do {
                        let sandbox = try Sandbox(for: imageURL)
                        if createSidecarFiles {
                            try sandbox.makeSidecarFile()
                            sidecarCreated = true
                        }
                        if let backupURL {
                            // make backup
                        }
                        // save changes
                        if tagFiles {
                            // tag file
                        }
                        return TaskInfo(id: id, metadata: metadata,
                                        sidecarCreated: sidecarCreated,
                                        status: true)
                    } catch {
                        return TaskInfo(id: id, metadata: metadata,
                                        sidecarCreated: sidecarCreated,
                                        status: false)
                    }
                }
            }

            for await taskInfo in group {
                if taskInfo.sidecarCreated {
                    await MainActor.run {
                        store.send(.sidecarCreated(taskInfo.id), undoable: false)
                    }
                }
                if taskInfo.status {
                    await MainActor.run {
                        store.send(.imageSaved(taskInfo.id, taskInfo.metadata),
                                   undoable: false)
                    }
                } else {
                    updateOK = false
                }
            }
        }
        return updateOK
    }

    func saveToXmp(_ info: [ImageData.ID: Metadata]) async -> Bool {
        // TODO
        print("saving to xmp")
        return true
    }
}
