//
//  Selections.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/29/22.
//

import Foundation

extension AppState {

    // Process the set of selected images.  Pick one as the "most" selected
    // and make its thumbnail NSImage.

    func selectionChanged(newSelection: Set<ImageModel.ID>) {
        guard !newSelection.isEmpty else {
            selectedImage = nil
            pinEnabled = false
            return
        }

        // filter out any ids in the selection that don't reference valid images
        let filteredImagesIds = images.filter { $0.isValid }.map { $0.id }
        let selection = newSelection.filter {
            filteredImagesIds.contains($0)
        }

        // Handle the case where nothing is selected
        guard !selection.isEmpty else {
            selectedImage = nil
            pinEnabled = false
            return
        }

        // If the image that was the "most" selected is in the current
        // selection set there is nothing more to do.
        if selection.contains(where: { $0 == selectedImage }) {
            return
        }

        // set the most selected image and its thumbnail. Mark its location
        // on the map.

        selectedImage = selection.first
        updatePin(location: self[selectedImage!].location)
        self[selectedImage!].makeThumbnail()
    }
}
