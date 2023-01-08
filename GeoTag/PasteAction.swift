//
//  PasteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import AppKit

// "Paste" into all selected images or a specific image in context
// selected images

extension ViewModel {
    // return true if paste actions should be disabled
    func pasteDisabled(context: ImageModel.ID? = nil) -> Bool {
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string),
           let _ = ImageModel.decodeStringRep(value: pasteVal),
           (context != nil || mostSelected != nil) {
            return false
        }
        return true
    }

    func pasteAction(context: ImageModel.ID?) {
        var imagesToUpdate = Set<ImageModel.ID>()

        // make the set of images to update.  It may be the single
        // image from a context menu or the entire set of selected images.
        if let id = context {
            imagesToUpdate.insert(id)
        } else {
            imagesToUpdate = selection
        }

        if !imagesToUpdate.isEmpty {
            // UNDO grouping
            let pb = NSPasteboard.general
            if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string),
               let locn = ImageModel.decodeStringRep(value: pasteVal) {
                undoManager.beginUndoGrouping()
                imagesToUpdate.forEach { id in
                    update(id: id, location: locn.0, elevation: locn.1)
                }
                undoManager.endUndoGrouping()
                undoManager.setActionName("paste location")
            }
        }
    }
}
