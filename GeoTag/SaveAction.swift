//
//  SaveAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {
    // return true if the save menu item should be disabled
    func saveDisabled() -> Bool {
        return !(window?.isDocumentEdited ?? false)
    }

    func saveAction() {
        // handle here
        window?.isDocumentEdited = false
    }
}

