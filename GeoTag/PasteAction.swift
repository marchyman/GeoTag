//
//  PasteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import AppKit

// "Paste" into all selected images or a specific image in context
// selected images

extension AppState {

    // return true if paste actions should be disabled.  Paste action always
    // allowed when editing a textfield

    func pasteDisabled(context: ImageModel? = nil,
                       textfield: Bool = false) -> Bool {
        guard !textfield else { return false }
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string),
           ImageModel.decodeStringRep(value: pasteVal) != nil,
           context != nil || tvm.mostSelected != nil {
            return false
        }
        return true
    }

    // paste into all selected images

    func pasteAction(context: ImageModel? = nil,
                     textfield: Bool = false) {
        if textfield {
            NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
        } else {
            if let context {
                tvm.select(context: context)
            }
            let pb = NSPasteboard.general
            if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string),
               let locn = ImageModel.decodeStringRep(value: pasteVal) {
                undoManager.beginUndoGrouping()
                for image in tvm.selected {
                    update(image, location: locn.0, elevation: locn.1)
                }
                undoManager.endUndoGrouping()
                undoManager.setActionName("paste location")
            }
        }
    }
}
