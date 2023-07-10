//
//  DeleteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import AppKit

// Program "Delete" action removes location information for all
// selected images

extension AppState {

    // should the delete action be disabled for a specific item or for
    // all selected items

    func deleteDisabled(context: ImageModel? = nil) -> Bool {
        if let image = context {
            return image.location == nil
        }
        return !tvm.selection.contains(where: { tvm[$0].location != nil })
    }

    // when textfield is non-nil a textfield is being edited and delete is
    // limited to the field.  Otherwise delete location info from the image
    // in the given context or all selected images when the context is nil.

    func deleteAction(context: ImageModel? = nil,
                      textfield: Double?? = nil) {
        if textfield == nil {
            if let context {
                tvm.select(context: context)
            }
            if !tvm.selection.isEmpty {
                undoManager.beginUndoGrouping()
                for id in tvm.selection where tvm[id].location != nil {
                    update(id: id, location: nil)
                }
                undoManager.endUndoGrouping()
                undoManager.setActionName("delete locations")
            }
        } else {
            NSApp.sendAction(#selector(NSText.delete(_:)), to: nil, from: nil)
        }
    }
}
