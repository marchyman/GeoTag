//
//  GpxSearch.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import CoreLocation
import Foundation

extension GpxTrackLog {

    /// Search for the last point in the track log with a timestamp <= the
    /// timestamp of a given image.
    ///
    /// - Parameter imageTime:    the time from epoch of an image whose
    ///                           coords are desired
    /// - Parameter extendTime:   number of minutes beyond the ends of
    ///                           track logs that can match an image timestamp.
    ///                           Default is 2 hours
    ///

    public func search(
        imageTime: TimeInterval,
        extendedTime: Double = 120.0
    ) async
        -> (CLLocationCoordinate2D, Double?)?
    {
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
            // if the point timestamp isn't within extendedTime of the image
            // timestamp do not treat it as a match.
            if (last.timeFromEpoch - imageTime).magnitude < extendedTime * 60 {
                return (
                    CLLocationCoordinate2D(
                        latitude: last.lat,
                        longitude: last.lon),
                    last.ele
                )
            }
        }
        return nil
    }
}
