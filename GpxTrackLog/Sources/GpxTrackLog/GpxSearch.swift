import CoreLocation
import Foundation

extension GpxTrackLog {

    /// Search for the last point in the track log with a timestamp <= the
    /// timestamp of a given image.
    ///
    /// - Parameter imageTime:    the time from epoch of an image whose
    ///                           coords are desired
    /// - Parameter extendedTime: number of minutes that a tracklog entry can
    ///                           vary to match the image timestamp.
    ///                           Default is 2 hours (120 minutes)
    ///

    public func search(imageTime: TimeInterval,
                       extendedTime: Double = 120.0)
    -> (CLLocationCoordinate2D, Double?)? {
        var lastPoint: Point?
        var lastDelta: Double = 0

        // extendedTime must not be zero. Use a minimum of 60 seconds.
        // (A zero value would cause the algorithm to only match points
        // with exactly the same timestamp as the image).
        let extendedSeconds = extendedTime == 0 ? 60 : extendedTime * 60

        for track in tracks {
            for segment in track.segments {
                // points that might be a match
                let possiblePoints = segment.points.prefix {
                    $0.timeFromEpoch <= imageTime
                }

                // use the last possible point. If there are now
                // possible points use the first point in the segment
                // if greater than the image time.
                let potentialMatch: GpxTrackLog.Point?
                if let lastPoint = possiblePoints.last {
                    potentialMatch = lastPoint
                } else if let firstPoint = segment.points.first,
                          imageTime <= firstPoint.timeFromEpoch {
                    potentialMatch = firstPoint
                } else {
                    potentialMatch = nil
                }

                // compare any potential match with any previously found
                // point. Keep the one with a timestamp closest to that
                // of the image.
                if let potentialMatch {
                    let potentialDelta = (potentialMatch.timeFromEpoch - imageTime).magnitude
                    if lastPoint == nil || potentialDelta < lastDelta {
                        lastPoint = potentialMatch
                        lastDelta = potentialDelta
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
            if lastDelta < extendedSeconds {
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
