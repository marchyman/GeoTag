//
//  CutCopyAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/31/22.
//

import Foundation

extension AppState {
    // return true if cut or copy actions should be disabled
    // if context is nil use selectedImage
    func cutCopyDisabled(context: ImageModel.ID? = nil) -> Bool {
        if let id = context != nil ? context : selectedImage {
            return self[id].location == nil
        }
        return true
    }

    func cutAction(context: ImageModel.ID? = nil) {
        // UNDO here
        copyAction(context: context)
        if let id = context != nil ? context : selectedImage {
            deleteAction(context: id)
        }

        // handle context paste and selection paste
    }

    func copyAction(context: ImageModel.ID? = nil) {
        // UNDO here
        if let id = context != nil ? context : selectedImage {
            print("copy \(self[id].location)")
        }
    }

}

