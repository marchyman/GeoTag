//
//  TableViewSelections.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/29/22.
//

import Foundation

extension TableViewModel {

    // Process the set of selected images.  Pick one as the "most" selected if
    // the current most selected image is not in the set.  Filter out any
    // items that are not valid images.

    func selectionChanged() {
        let id = markStart("selectionChanged")

        selected = selection.map({ self[$0] }).filter { $0.isValid }
        let updatedSelection = selection.intersection(selected.map { $0.id })

        // Handle the case where nothing is selected.  Otherwise pick an
        // id as being the "most selected".
        if selected.isEmpty {
            mostSelected = nil
        } else {
            // If the image that was the "most" selected is in the proposed
            // selection set don't pick another
            if !selected.contains(where: { $0 == mostSelected }) {
                let id = markStart("changeMostSelected")
                mostSelected = selected.first
                markEnd("changeMostSelected", interval: id)
            }
        }

        // update the selection if necessary
        if updatedSelection != selection {
            selection = updatedSelection
        }
        markEnd("selectionChanged", interval: id)
    }

    // If the context item is in the current selection make it the
    // mostSelected item, otherwise replace the current selection
    // with the item.

    func select(context: ImageModel) {
        if context.isValid {
            if selection.contains(context.id) {
                mostSelected = context
            } else {
                selection = [context.id]
            }
        }
    }
}
