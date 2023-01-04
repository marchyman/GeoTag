//
//  DiscardTracksAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension ViewModel {
    // return true if the save menu item should be disabled
    func discardTracksDisabled() -> Bool {
        return gpxTracks.isEmpty
    }

    // clear out all track related data and trigger a refresh which will
    // remove any existing tracks from the map.
    func discardTracksAction() {
        gpxTracks = []
        mapLines = []
        mapSpan = nil
        mapCenter = nil
        refreshTracks = true
    }
}

