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

    func locnFromTrackAction(context: ImageModel? = nil,
                             extendedTime: Double) {
        if let context {
            tvm.select(context: context)
        }

        // use a separate task in a group to update each image
        // copy the current selection in case it changes while the update
        // is running.
        let selectedImages = tvm.selected
        Task {
            applicationBusy = true
            undoManager.beginUndoGrouping()
            await updateImageLocations(for: selectedImages,
                                       extendedTime: extendedTime)
            undoManager.endUndoGrouping()
            undoManager.setActionName("locn from track")
            applicationBusy = false
        }
    }

    nonisolated private func updateImageLocations(
        for images: [ImageModel],
        extendedTime: Double) async {
        // image timestamps must be converted to seconds from the epoch
        // to match track logs.  Prepare a dateformatter to handle the
        // conversion.

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = await timeZone

        await withTaskGroup(of: (Coords, Double?)?.self) { group in
            for image in images {
                group.addTask { [self] in
                    var found: [(Coords, Double?)] = []

                    // search ALL known tracklogs for the timestamp of the
                    // given image.

                    if let convertedDate = dateFormatter.date(from: image.timeStamp) {
                        for track in await gpxTracks {
                            if let locn = await track.search(
                                imageTime: convertedDate.timeIntervalSince1970,
                                extendedTime: extendedTime)
                            {
                                found.append(locn)
                            }
                        }
                    }

                    // return the last entry found. If the entry was in multiple
                    // tracklogs the last entry will be the entry closest to
                    // timestamp of the image because the gpxTracks array is
                    // assumed to be sorted by timestamp.

                    return found.last
                }

                for await locn in group {
                    if let locn {
                        await MainActor.run {
                            update(image, location: locn.0, elevation: locn.1)
                        }
                    }
                }
            }
        }
    }
}
