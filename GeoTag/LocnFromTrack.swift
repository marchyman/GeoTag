//
//  LocnFromTrack.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {
    func locnFromTrackDisabled(context: ImageModel.ID? = nil) -> Bool {
        if gpxTracks.count > 0 {
            if context != nil || mostSelected != nil {
                return false
            }
        }
        return true
    }

    func locnFromTrackAction() {
        var imagesToUpdate = Set<ImageModel.ID>()

        // make the set of images to update.  It may be the single
        // image from a context menu or the entire set of selected images.
        if let id = menuContext {
            imagesToUpdate.insert(id)
        } else {
            imagesToUpdate = selection
        }

        // Handle UNDO grouping here
        let updateGroup = DispatchGroup()
        imagesToUpdate.forEach { id in
            DispatchQueue.global(qos: .userInitiated).async {
                updateGroup.enter()
                self.gpxTracks.forEach {
                    $0.search(timeStamp: self[id].timeStamp) { location in
                        DispatchQueue.main.async {
                            self.update(id: id, location: location)
                        }
                    }
                }
                updateGroup.leave()
            }
        }
        updateGroup.notify(queue: DispatchQueue.main) {
            print("Locn From Track finished")
        }
    }
}
