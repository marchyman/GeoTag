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

        // use a separate task in a group to update each image
        Task {
            applicationBusy = true
            undoManager.beginUndoGrouping()
            await updateImageLocations(for: tvm.selected)
            undoManager.endUndoGrouping()
            undoManager.setActionName("locn from track")
            applicationBusy = false
        }
    }

    nonisolated private
    func updateImageLocations(for images: [ImageModel]) async {
        // image timestamps must be converted to seconds from the epoch
        // to match track logs.  Prepare a dateformatter to handle the
        // conversion.

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = await timeZone

        await withTaskGroup(of: (Coords, Double?)?.self) { group in
            for image in images {
                group.addTask { [self] in
                    if let convertedDate = dateFormatter.date(from: image.timeStamp) {
                        for track in await gpxTracks {
                            if let locn = await track.search(imageTime: convertedDate.timeIntervalSince1970) {
                                return locn
                            }
                        }
                    }
                    return nil
                }

                for await locn in group {
                    if let locn {
                        await MainActor.run {
                            update(image, location: locn.0,
                                   elevation: locn.1)
                        }
                    }
                }
            }
        }
    }
}
