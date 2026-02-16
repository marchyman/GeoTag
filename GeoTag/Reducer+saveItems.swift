import ImageData

extension GeoTagReducer {
    func save(_ state: inout GeoTagState) {
        // TODO:
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

    func discardTracks(_ state: inout GeoTagState) {
        state.gpxTracks.removeAll()
        // TODO: remove tracks from map
    }

    func clearImages(_ state: inout GeoTagState) {
        state.selection = []
        for url in state.scopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        state.scopedURLs.removeAll()
        state.imageData.removeAll()
    }
}

