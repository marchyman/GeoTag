//
//  LocnFromTrack.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension AppState {

    func locnFromTrackDisabled(context: ImageModel? = nil) -> Bool {
        if gpxTracks.count > 0 {
            if let image = context {
                return !image.isValid
            }
            if let image = tvm.mostSelected {
                return !image.isValid
            }
        }
        return true
    }

    func locnFromTrackAction(context: ImageModel? = nil) {
        if let context {
            tvm.select(context: context)
        }
        // image timestamps must be converted to seconds from the epoch
        // to match track logs.  Prepare a dateformatter to handle the
        // conversion.

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = timeZone

        // use a separate task in a group to update each image
        Task { @MainActor in
            applicationBusy = true
            await withTaskGroup(of: (Coords, Double?)?.self) { group in
                for id in tvm.selection {
                    if let convertedDate = dateFormatter.date(from: tvm[id].timeStamp) {
                        group.addTask { [self] in
                            // do not use forEach as once a match is
                            // found there is no need to search other tracks for
                            // the current image.
                            for track in gpxTracks {
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
            applicationBusy = false
        }
    }
}
