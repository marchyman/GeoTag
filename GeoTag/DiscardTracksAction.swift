//
//  DiscardTracksAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {
    // return true if the save menu item should be disabled
    func discardTracksDisabled() -> Bool {
        return gpxTracks.isEmpty
    }

    func discardTracksAction() {
        // handle here
    }
}

