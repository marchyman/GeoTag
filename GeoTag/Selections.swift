//
//  Selections.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/29/22.
//

import Foundation

extension ViewModel {

    // Process the set of selected images.  Pick one as the "most" selected
    // and make its thumbnail NSImage.

    func selectionChanged(newSelection: Set<ImageModel.ID>) {
        // filter out any ids in the selection that don't reference valid images
        let filteredImagesIds = images.filter { $0.isValid }.map { $0.id }
        selection = newSelection.filter { filteredImagesIds.contains($0) }

        // Handle the case where nothing is selected
        guard !selection.isEmpty else {
            mostSelected = nil
            return
        }

        // If the image that was the "most" selected is in the current
        // selection set there is nothing more to do.
        if selection.contains(where: { $0 == mostSelected }) {
            return
        }

        // set the most selected image and its thumbnail. Mark its location
        // on the map.

        mostSelected = selection.first
        self[mostSelected!].makeThumbnail()
    }
}
