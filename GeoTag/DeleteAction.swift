//
//  DeleteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import Foundation

// Program "Delete" action removes location information for all
// selected images

extension ViewModel {

    // should the delete action be disabled for a specific item or for
    // all selected items
    func deleteDisabled(context: ImageModel.ID? = nil) -> Bool {
        if let id = context {
            return self[id].location == nil
        }
        return !selection.contains(where: { self[$0].location != nil })
    }

    func deleteAction(context: ImageModel.ID? = nil) {
        if let id = context {
            // delete location from a specific item
            update(id: id, location: nil)
            undoManager.setActionName("delete location")
        } else {
            // delete location from all selected items
            if !selection.isEmpty {
                undoManager.beginUndoGrouping()
                for id in selection {
                    if self[id].location != nil {
                        update(id: id, location: nil)
                    }
                }
                undoManager.endUndoGrouping()
                undoManager.setActionName("delete locations")
            }
        }
    }
}
