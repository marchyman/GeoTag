//
//  DiscardChangesAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension ViewModel {
    // return true if the save menu item should be disabled
    func discardChangesDisabled() -> Bool {
        return !(window?.isDocumentEdited ?? false)
    }

    func discardChangesAction() {
        // walk through the array of images calling the revert() function
        var index = images.startIndex
        while index < images.endIndex {
            images[index].revert()
            index = images.index(after: index)
        }
        undoManager.removeAllActions()
        window?.isDocumentEdited = false
    }
}

