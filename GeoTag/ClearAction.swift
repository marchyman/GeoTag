//
//  ClearAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/24/22.
//

import Foundation

// Program "Clear List" action removes removes

extension AppState {
    // should the delete action be enabled
    var canClearImageList: Bool {
        !images.isEmpty && !window.isDocumentEdited
    }

    func clearImageListAction() {
        if canClearImageList {
            selection = Set()
            processedURLs = Set()
            images = []
        }
    }
}
