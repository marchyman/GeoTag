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
