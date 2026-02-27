import CoreLocation
import Foundation
import ImageData
import Metadata
import Photos
import Phototool

extension GeoTagReducer {
    func save(_ state: inout GeoTagState) {
        // @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
        // @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()
        //
        // Update data for images that came from the photos library
        let libraryPhotosToSave = state.imageData.indices.filter {
            if case .photos(_, _) = state.imageData[$0].metadata.source,
                state.imageData[$0].updatable {
                return true
            }
            return false
        }
        if !libraryPhotosToSave.isEmpty {
            saveLibraryPhotos(indices: libraryPhotosToSave, state: &state)
            // TODO update metadata here?
            // but actual updates may still be in progress running
            // on another task.
        }
 

        // // get the image files that need saving
        // let imagesToSave = tvm.images.filter { $0.asset == nil && $0.changed }
        //
        // // before starting check if a backup folder is needed
        // guard imagesToSave.isEmpty || doNotBackup || backupURL != nil else {
        //     addSheet(type: .noBackupFolderSheet)
        //     return
        // }
        //
        // saveInProgress = true
        // undoManager.removeAllActions()
        // isDocumentEdited = false
        //
        // // process the image file saves in the background.
        // Task {
        //     saveIssues = await saveImageFiles(images: imagesToSave)
        //     if !saveIssues.isEmpty {
        //         isDocumentEdited = true
        //         addSheet(type: .saveErrorSheet)
        //     }
        //     saveInProgress = false
        // }
        // TODO:
    }

    private func saveLibraryPhotos(indices: [Int], state: inout GeoTagState) {
        struct UpdateInfo {
            var asset: PHAsset
            var timestamp: Date?
            var location: CLLocation?
        }

        var updateInfo: [UpdateInfo] = []

        // go through the images and accumulate data to update
        for ix in indices {
            if case .photos(_, let asset) = state.imageData[ix].metadata.source,
               let asset {
                if state.imageData[ix].metadata != state.imageData[ix].original {
                    let timestamp: Date? =
                        if state.imageData[ix].metadata.dateTimeCreated !=
                            state.imageData[ix].original?.dateTimeCreated {
                            state.imageData[ix].metadata.date()
                        } else {
                            nil
                        }
                    let location: CLLocation? =
                        if !state.imageData[ix].metadata
                            .matchesLocation(state.imageData[ix].original) {
                            state.imageData[ix].location(nil)
                        } else {
                            nil
                        }
                    updateInfo.append(UpdateInfo(asset: asset,
                                                 timestamp: timestamp,
                                                 location: location))
                }
            }
        }
        // perform the needed updates in a task
        Task {
            for info in updateInfo {
                await Phototool.update(timestamp: info.timestamp,
                                       location: info.location,
                                       for: info.asset)
            }
        }
    }

    func discardChanges(_ state: inout GeoTagState) {
        for ix in state.imageData.indices {
            if let original = state.imageData[ix].original {
                if state.imageData[ix].metadata != original {
                    state.imageData[ix].metadata.restore(from: original)
                }
            }
        }
        state.unsavedChanges = false
    }

    func clearImages(_ state: inout GeoTagState) {
        state.mostSelected = nil
        state.selection = []
        for url in state.scopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        state.scopedURLs.removeAll()
        state.imageData.removeAll()
    }
}
