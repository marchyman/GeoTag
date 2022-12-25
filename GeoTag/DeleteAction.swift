//
//  DeleteAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import Foundation

// Program "Delete" action removes location information for all
// selected images

extension AppState {
    // should the delete action be enabled
    var canDelete: Bool {
        images.contains { image in
            selection.contains(image.id) &&
            image.isValid &&
            image.location != nil
        }
    }

    func deleteAction() {
        // UNDO here
        for image in images.filter({ selection.contains($0.id) &&
                                     $0.isValid && $0.location != nil }) {
            image.location = nil
            window.isDocumentEdited = true
        }
    }
}
