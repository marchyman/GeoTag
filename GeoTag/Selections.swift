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
            selectedImageThumbnail = nil
            pinEnabled = false
            return
        }

        // filter out any ids in the selection that don't reference valid images
        let filteredImagesIds = images.filter { $0.isValid }.map { $0.id }
        let filteredSelection = newSelection.filter {
            filteredImagesIds.contains($0)
        }

        // Update the selection if the counts don't match
        if selection.count != filteredSelection.count {
            selection = filteredSelection
            guard !selection.isEmpty else {
                selectedImage = nil
                selectedImageThumbnail = nil
                pinEnabled = false
                return
            }
        }

        // If an image was selected and is in the new group of selected images
        // leave it alone.
        // Mark the location of any new selection on the map.

        if let image = selectedImage,
           selection.contains(where: { $0 == image.id }) {
            return
        }

        // set the most selected image and its thumbnail. Mark its location
        // on the map.

        selectedImage = images.first { $0.id == selection.first }
        updatePin(location: selectedImage?.location)
        Task {
            selectedImageThumbnail = await selectedImage!.makeThumbnail()
        }
    }

    // Is there a selected and valid image?  THIS SHOULD GO AWAY
    var isSelectedImageValid: Bool {
        selectedImage?.isValid ?? false
    }
}
