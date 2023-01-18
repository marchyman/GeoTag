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

    // paste into all selected images
    
    func pasteAction() {
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string),
           let locn = ImageModel.decodeStringRep(value: pasteVal) {
            undoManager.beginUndoGrouping()
            for id in selection {
                update(id: id, location: locn.0, elevation: locn.1)
            }
            undoManager.endUndoGrouping()
            undoManager.setActionName("paste location")
        }
    }
}
