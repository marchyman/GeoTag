//
//  GpxSearch.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension GpxTrackLog {

    /// Search for the last point in the track log with a timestamp <= the
    /// timestamp of a given image.
    ///
    /// - Parameter imageTime: the  time from epoch of an image whose coords are desired
    ///

    func search(imageTime: TimeInterval) async -> (Coords, Double?)? {
        var lastPoint: Point?

        // search every track for the last point with a timestamp <= the
        // image timestamp.   The location of the found point (if any)
        // will be used as the image location.  All tracks must be searched
        // as tracks are not sorted

        for track in tracks {
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
            // we have a point. But does it make sense, meaning is the point
            // for some location reported many days from the image timestamp?
            // if the point timestamp isn't within +/- 21600 seconds of the
            // image timestamp (6 hours) do not treat it as a match.
            // 21600 is an arbitrary value picked out of thin air.
            if (last.timeFromEpoch - imageTime).magnitude < 21600 {
                return (Coords(latitude: last.lat, longitude: last.lon),
                        last.ele)
            }
        }
        return nil
    }
}
