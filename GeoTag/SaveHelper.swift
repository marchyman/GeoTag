import ImageData
import Imagetool
import Metadata
import Phototool
import SwiftUI
import UDF

@MainActor
enum SaveHelper {
    @discardableResult
    static func save(_ store: Store<GeoTagState, GeoTagEvent>) -> Task<Void, Never> {
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
        // Do the save in the background, report when done.
        let task = Task {
            async let libUpdated = saveToLibrary(store, libraryImages)
            async let imgUpdated = saveToImage(store, fileImages)
            async let xmpUpdated = saveToImage(store, xmpImages, xmp: true)

            let ok = await [libUpdated, imgUpdated, xmpUpdated]
            store.send(.saveComplete(ok.allSatisfy { $0 == true }),
                       undoable: false)
        }
        return task
    }

    static func saveToLibrary(_ store: Store<GeoTagState, GeoTagEvent>,
                              _ info: [ImageData.ID: Metadata]) async -> Bool {
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

    // pass copy of MainActor related data to a nonisolated function
    // that will perform updates in parallel

    static func saveToImage(_ store: Store<GeoTagState, GeoTagEvent>,
                            _ info: [ImageData.ID: Metadata],
                            xmp: Bool = false) async -> Bool {
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

        // common work down, image vs xmp updates are slightly different
        if xmp {
            return await saveToXmpTasks(store, info, backupURL, store.timeZone,
                                        addTags, tagName)
        }
        return await saveToImageTasks(store, info, createSidecarFiles,
                                      backupURL, store.timeZone,
                                      addTags, tagName)
    }

    // Update the items in the info dictionary in a task group

    // swiftlint:disable:next function_parameter_count
    nonisolated static func saveToImageTasks(_ store: Store<GeoTagState, GeoTagEvent>,
                                             _ info: [ImageData.ID: Metadata],
                                             _ createSidecarFiles: Bool,
                                             _ backupURL: URL?,
                                             _ timeZone: TimeZone?,
                                             _ tagFiles: Bool,
                                             _ tagName: String) async -> Bool {
        var updateOK = true
        struct TaskInfo {
            let id: ImageData.ID
            let metadata: Metadata
            let sidecarCreated: Bool
            let status: Bool
        }

        // TODO: max concurrent tasks
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
                            try await sandbox.makeBackupFile(backupFolder: backupURL)
                        }
                        try await sandbox.saveChanges(from: metadata,
                                                      timeZone: timeZone)
                        if tagFiles {
                            try await sandbox.setTag(name: tagName)
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

    // swiftlint:disable:next function_parameter_count
    nonisolated static func saveToXmpTasks(_ store: Store<GeoTagState, GeoTagEvent>,
                                           _ info: [ImageData.ID: Metadata],
                                           _ backupURL: URL?,
                                           _ timeZone: TimeZone?,
                                           _ tagFiles: Bool,
                                           _ tagName: String) async -> Bool {
        var updateOK = true
        struct TaskInfo {
            let id: ImageData.ID
            let metadata: Metadata
            let status: Bool
        }

        // TODO: max concurrent tasks
        await withTaskGroup(of: TaskInfo.self) { group in
            for (id, metadata) in info {
                group.addTask {
                    guard case .xmp(let imageURL) = metadata.source else {
                        return TaskInfo(id: id, metadata: metadata,
                                        status: false)
                    }

                    do {
                        let sandbox = try Sandbox(for: imageURL)
                        if let backupURL {
                            try await sandbox.makeSidecarBackup(backupURL)
                        }
                        try await sandbox.saveChanges(from: metadata,
                                                      timeZone: timeZone)
                        if tagFiles {
                            try await sandbox.setTag(name: tagName)
                        }
                        return TaskInfo(id: id, metadata: metadata,
                                        status: true)
                    } catch {
                        return TaskInfo(id: id, metadata: metadata,
                                        status: false)
                    }
                }
            }

            for await taskInfo in group {
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
}
