//
//  Selections.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/29/22.
//

import Foundation

extension AppViewModel {

    // Process the set of selected images.  Pick one as the "most" selected if
    // the current most selected image is not in the set.  Filter out any
    // items that are not valid images.

    func selectionChanged() {

        // filter out any ids in the selection that don't reference valid images
        let filteredImageIds = images.filter { $0.isValid }.map { $0.id }
        let proposedSelection = selection.filter { filteredImageIds.contains($0) }

        // Handle the case where nothing is selected.  Otherwise pick an
        // id as being the "most selected".
        if proposedSelection.isEmpty {
            mostSelected = nil
        } else {
            // If the image that was the "most" selected is in the proposed
            // selection set don't pick another
            if !proposedSelection.contains(where: { $0 == mostSelected }) {
                mostSelected = selection.first
            }
        }

        // if the proposed selection does not match the selection update
        // the selection on the main queue.
        if proposedSelection != selection {
            DispatchQueue.main.async {
                self.selection = proposedSelection
            }
        }
    }

    // If the context item is in the current selection make it the
    // mostSelected item, otherwise replace the current selection
    // with the item.

    func select(context: ImageModel.ID) {
        if self[context].isValid {
            if selection.contains(context) {
                mostSelected = context
            } else {
                selection = [context]
            }
        }
    }
}
