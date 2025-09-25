# GPX Track Log Processing

This code was extracted from GeoTag and turned into a package for
better program organization.  The package consists of two main functions,
one function to parse GPX files for track logs and a second to search
track logs for track points by timestamp.

Given a URL to a GPX file a searchable track log is created by

```swift
    let tracklog = try GpxTrackLog(contentsOf: url)
```

A tracklog may contain multiple tracks and a track can be made up of multiple
segments. A segment is made up of points.

```swift
extension GpxTrackLog {
    // Tracks are made up of one or more Segments.
    public struct Track: Sendable {
        public var segments = [Segment]()
    }

    // Segments are made up of Points.
    public struct Segment: Sendable {
        public var points = [Point]()
    }

    // points contain (at least) a latitude, longitude, and timestamp.
    public struct Point: Equatable, Sendable {
        public let lat: Double
        public let lon: Double
        public var ele: Double?
        public var timeFromEpoch: TimeInterval
    }
}
```

Tracks can be converted to an array of CLLocationCoordinate2D for use in
maps and elsewhere using code such as:

```swift
    func updateTracks(tracklog: GpxTrackLog,
                      processSegment: ([CLLocationCoordinate2d]) -> ())
        guard trackLog.tracks.count > 0 else { return}
        for track in trackLog.tracks {
            for segment in track.segments {
                let trackCoords = segment.points.map {
                    CLLocationCoordinate2D(latitude: $0.lat,
                                           longitude: $0.lon)
                }
                if !trackCoords.isEmpty {
                    processSegment(trackCoords)
                }
            }
        }
    }
```

Track log searches return the latitude, longitude, and optional elevation of
the track point that is <= a given timestamp.  However, if any found point
has a timestamp that is not within 6 hours (an arbitrary value) of the
requested timestamp the search will return nil.

