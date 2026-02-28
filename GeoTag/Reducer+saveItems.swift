import CoreLocation
import Foundation
import ImageData
import Metadata
import Photos
import Phototool
import SwiftUI

extension GeoTagReducer {

    // save the indices of all updatable images that have changed.
    // The save process continues in a future step.

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
