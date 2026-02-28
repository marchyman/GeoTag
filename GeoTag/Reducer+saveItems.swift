import CoreLocation
import Foundation
import ImageData
import Metadata
import Photos
import Phototool
import SwiftUI

extension GeoTagReducer {
    // save the indices of all updatable images that have changed.
    // The save process continues as the next step.

    func save(_ state: inout GeoTagState) {
        state.saveInProgress = true
        state.libraryImages = state.imageData.indices
            .filter {
                if case .photos = state.imageData[$0].metadata.source,
                   state.imageData[$0].updatable,
                   state.imageData[$0].metadata != state.imageData[$0].original {
                    return true
                }
                return false
            }
        state.fileImages = state.imageData.indices.filter {
            if case .image = state.imageData[$0].metadata.source,
               state.imageData[$0].updatable,
               state.imageData[$0].metadata != state.imageData[$0].original {
                return true
            }
            return false
        }
        state.xmpImages = state.imageData.indices.filter {
            if case .xmp = state.imageData[$0].metadata.source,
               state.imageData[$0].updatable,
               state.imageData[$0].metadata != state.imageData[$0].original {
                return true
            }
            return false
        }
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
        // perform the needed updates in a task. I don't know
        // how well Photos handles parallelism or if at all. The
        // updates are done one at a time.
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

    private func checkOtherPhotos(_ state: GeoTagState) -> [ImageData.ID] {
        return state.imageData.indices.filter {
            if case .image = state.imageData[$0].metadata.source,
               case .xmp = state.imageData[$0].metadata.source,
               state.imageData[$0].updatable,
               state.imageData[$0].metadata != state.imageData[$0].original {
                return true
            }
            return false
        }
    }

    private func saveOtherPhotos(indices: [Int],
                                 state: GeoTagState,
                                 continuation: AsyncStream<Bool>.Continuation) {
        // TODO use a task group to fire off the exiftool task to
        // do the updates.
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
