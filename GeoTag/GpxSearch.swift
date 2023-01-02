//
//  GpxSearch.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension Gpx {
    static var dateFormatter = DateFormatter()

    /// Search for the last point in the track log with a timestamp <= the
    /// timestamp of a given image.
    ///
    /// - Parameter timeStamp: the timestamp of an image whose coords are desired
    /// - Parameter found: A closure envoked for the nearest point in the tracklog found
    func search(timeStamp: String,
                found: (Coords) -> ()) {
        let imageTime = intervalFromEpoch(timeStamp: timeStamp)
        var lastPoint: Point?

        // search every track for the last point with a timestamp <= the
        // image timestamp.   The location of the found point (if any)
        // will be used as the image location.  All tracks must be searched
        // as tracks are not sorted

        tracks.forEach {
            track in
            for segment in track.segments {
                let possiblePoints = segment.points.prefix {
                    $0.timeFromEpoch <= imageTime
                }
                if let segmentLast = possiblePoints.last {
                    if lastPoint == nil {
                        lastPoint = segmentLast
                    } else if segmentLast.timeFromEpoch > lastPoint!.timeFromEpoch {
                        lastPoint = segmentLast
                    }

                    // if this wasn't the last point in a segment we've
                    // found the last point in the current track.  Don't
                    // bother checking any remaining segments.

                    if possiblePoints.count != segment.points.count {
                        break
                    }
                }
            }
        }
        if let last = lastPoint {
            found(Coords(latitude: last.lat, longitude: last.lon))
        }
    }

    // convert an image timestamp to an interval from the epoch

    func intervalFromEpoch(timeStamp: String) -> TimeInterval {
        Gpx.dateFormatter.dateFormat = ImageModel.dateFormat
        Gpx.dateFormatter.timeZone = Gpx.timeZone
        if let convertedDate = Gpx.dateFormatter.date(from: timeStamp) {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }
}
