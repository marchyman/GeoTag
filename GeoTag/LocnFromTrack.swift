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

    func locnFromTrackAction(context: ImageModel.ID?) {
        var imagesToUpdate = Set<ImageModel.ID>()

        // make the set of images to update.  It may be the single
        // image from a context menu or the entire set of selected images.
        if let id = context {
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

        // use a separate task in a group to update each image
        Task {
            showingProgressView = true
            await withTaskGroup(of: (Coords, Double?)?.self) { group in
                for id in imagesToUpdate {
                    if let convertedDate = dateFormatter.date(from: self[id].timeStamp) {
                        group.addTask { [self] in
                            // do not use forEach/asyncForEach as once a match is
                            // found there is no need to search other tracks for
                            // the current image.
                            for track in await gpxTracks {
                                if let locn = await track.search(imageTime: convertedDate.timeIntervalSince1970) {
                                    return locn
                                }
                            }
                            return nil
                        }
                        undoManager.beginUndoGrouping()
                        for await locn in group {
                            if let locn {
                                update(id: id, location: locn.0,
                                       elevation: locn.1)
                            }
                        }
                        undoManager.endUndoGrouping()
                        undoManager.setActionName("locn from track")
                    }
                }
            }
            showingProgressView = false
        }
    }
}
