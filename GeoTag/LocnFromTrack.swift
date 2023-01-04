//
//  LocnFromTrack.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension ViewModel {
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

        // image timestamps must be converted to seconds from the epoch
        // to match track logs.  Prepare a dateformatter to handle the
        // conversion.

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = timeZone

        // Handle UNDO grouping here
        let updateGroup = DispatchGroup()
        imagesToUpdate.forEach { id in
            DispatchQueue.global(qos: .userInitiated).async {
                updateGroup.enter()
                // don't bother looking for a tracklog match if we can't
                // process the image date
                if let convertedDate = dateFormatter.date(from: self[id].timeStamp) {
                    self.gpxTracks.forEach {
                        $0.search(imageTime: convertedDate.timeIntervalSince1970) { location, elevation in
                            DispatchQueue.main.async {
                                self.update(id: id, location: location, elevation: elevation)
                            }
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
