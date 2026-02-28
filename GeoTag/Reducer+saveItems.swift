import CoreLocation
import Foundation
import ImageData
import Metadata
import Photos
import Phototool
import SwiftUI

extension GeoTagReducer {
    func save(_ state: inout GeoTagState,
              done: AsyncStream<Bool>.Continuation) {
        @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
        // @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()
        //

        state.saveInProgress = true

        // Update data for images that came from the photos library
        let libraryPhotosToSave = state.imageData.indices.filter {
            if case .photos = state.imageData[$0].metadata.source,
                state.imageData[$0].updatable {
                return true
            }
            return false
        }
        if libraryPhotosToSave.isEmpty {
            done.yield(false)
        } else {
            saveLibraryPhotos(indices: libraryPhotosToSave,
                              state: state,
                              continuation: done)
        }

        let imagesToSave = state.imageData.indices.filter {
            if case .image = state.imageData[$0].metadata.source,
               case .xmp = state.imageData[$0].metadata.source,
               state.imageData[$0].updatable {
                return true
            }
            return false
        }

        guard  imagesToSave.isEmpty || doNotBackup || state.backupURL != nil else {
            state.addSheet(type: .noBackupFolderSheet)
            done.yield(false)
            return
        }
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
        //     saveInProgress = false // not here
        // }
        // TODO:
        // pretend we've processed all images to save
        done.yield(true)

        state.saveInProgress = false
    }

    private func saveLibraryPhotos(indices: [Int],
                                   state: GeoTagState,
                                   continuation: AsyncStream<Bool>.Continuation) {
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
                // TODO: handle errors
            }
            continuation.yield(true)
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
