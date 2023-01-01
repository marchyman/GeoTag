//
//  DiscardChangesAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {
    // return true if the save menu item should be disabled
    func discardChangesDisabled() -> Bool {
        return !(window?.isDocumentEdited ?? false)
    }

    func discardChangesAction() {
        // handle here
        window?.isDocumentEdited = false
    }
}

