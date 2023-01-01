//
//  MenuAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

extension AppState {
    enum MenuAction: Identifiable {
        var id: Self {
            return self
        }

        case none
        case cut
        case copy
        case paste
        case delete
        case selectAll
        case save
        case discardChanges
        case discardTracks
        case clearList
    }

    // Do the requested action

    func menuAction(_ action: MenuAction) {
        self.selectedMenuAction = .none
        switch action {
        case .none:
            return
        case .cut:
            cutAction()
        case .copy:
            copyAction()
        case .paste:
            pasteAction()
        case .delete:
            deleteAction()
        case .selectAll:
            selection = Set(images.map { $0.id })
        case .save:
            saveAction()
        case .discardChanges:
            discardChangesAction()
        case .discardTracks:
            discardTracksAction()
        case .clearList:
            clearImageListAction()
        }
    }
}
