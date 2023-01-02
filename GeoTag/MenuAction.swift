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
        // file menu
        case save
        case discardChanges
        case discardTracks
        case clearList
        // edit menu
        case cut
        case copy
        case paste
        case delete
        case selectAll
        case showInFinder
        case locnFromTrack
        case adjustTimeZone
        case modifyDateTime
        case modifyLocation
    }

    // Do the requested action

    func menuAction(_ action: MenuAction) {
        self.selectedMenuAction = .none
        switch action {
        case .none:
            return
        case .save:
            saveAction()
        case .discardChanges:
            discardChangesAction()
        case .discardTracks:
            discardTracksAction()
        case .clearList:
            clearImageListAction()
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
        case .showInFinder:
            showInFinderAction()
        case .locnFromTrack:
            locnFromTrackAction()
        case .adjustTimeZone:
            return
        case .modifyDateTime:
            return
        case .modifyLocation:
            return
        }
    }
}
