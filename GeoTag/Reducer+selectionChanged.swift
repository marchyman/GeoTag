import ImageData
// import UDF

// Process selection changes in the table of images. The UI doesn't know
// that some of the displayed items are not selectable. Remove those items
// from the selection and pick one of the items as being `mostSelected`.

extension GeoTagReducer {

    func selectionChanged(_ state: inout GeoTagState,
                          selection: Set<ImageData.ID>) {
        // filter out items that are not updatable
        state.selection = selection.filter { state[$0].updatable }

        // Handle the case where nothing is selected.  Otherwise pick an
        // id as being the "most selected".
        if state.selection.isEmpty {
            state.mostSelected = nil
        } else if state.selection.count == 1 {
            state.mostSelected = state.selection.first
        } else {
            // If the image that was the "most" selected is in the proposed
            // selection set don't pick another
            if state.mostSelected == nil ||
                !state.selection.contains(state.mostSelected!) {
                state.mostSelected = state.selection.first
            }
        }
    }

    func mostSelectedChanged(_ state: inout GeoTagState,
                             mostSelected: ImageData.ID) {
        if !state.selection.contains(mostSelected) {
            state.selection.insert(mostSelected)
        }
        state.mostSelected = mostSelected
    }
}
