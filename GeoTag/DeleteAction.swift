//
//  DeleteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import Foundation

// Program "Delete" action removes location information for all
// selected images

extension AppViewModel {

    // should the delete action be disabled for a specific item or for
    // all selected items

    func deleteDisabled(context: ImageModel.ID? = nil) -> Bool {
        if let id = context {
            return self[id].location == nil
        }
        return !selection.contains(where: { self[$0].location != nil })
    }

    // delete location info from all selected images
    
    func deleteAction() {
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
