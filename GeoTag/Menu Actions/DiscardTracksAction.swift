//
//  DiscardTracksAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {

    // return true if the discard tracks menu item should be disabled

    func discardTracksDisabled() -> Bool {
        return gpxTracks.isEmpty
    }

    // clear out all track related data and trigger a refresh which will
    // remove any existing tracks from the map.

    func discardTracksAction() {
        gpxTracks = []
        masData.removeTracks()
    }
}
