//
//  Gpx.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/22/18.
//  Copyright © 2018,2019,2022 Marco S Hyman. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//

import Foundation

/// GPX file processing

class Gpx: NSObject {
    /// TimeZone
    ///
    /// Holds the optional timezone to use with image timestamp when matching image to tracklog.
    static var timeZone: TimeZone?

    // GPX Parsing errors
    enum GpxParseError: Error {
        case gpxOpenError
        case gpxNoPoints
        case gpxParsingError
    }

    // parser states
    enum ParseState {
        case none       // starting state
        case trk        // <trk> seen
        case trkSeg     // <trkseg> seen
        case trkPt      // <trkpt> seen
        case time       // <time> inside of a <trkpt>
        case ele        // <ele> inside of a <trkpt>
        case error      // bad GPX file
    }

    /// A track consists of one or more track segments
    struct Track {
        var segments = [Segment]()
    }

    /// A track segment consists of one or more track points
    struct Segment {
        var points = [Point]()
    }

    /// date formater for track point timestamps.
    static let pointTimeFormat = ISO8601DateFormatter()

    /// Track points contain (at least) a latitude, longitude, and timestamp
    struct Point : Equatable {
        let lat: Double
        let lon: Double
        var ele: Double?
        var time: String
        var timeFromEpoch: TimeInterval {
            let trimmedTime = time.replacingOccurrences(of: "\\.\\d+", with: "",
                                                        options: .regularExpression)
            if let convertedTime = pointTimeFormat.date(from: trimmedTime) {
                return convertedTime.timeIntervalSince1970
            }
            return 0
        }
    }

    var parser: XMLParser
    var tracks = [Track]()
    var parseState = ParseState.none

    // Access/update the last track, segment, or point in the tracks array
    var lastTrack: Track? {
        get { return tracks.last }
        set {
            if newValue == nil {
                parseState = .error
            } else {
                tracks.append(newValue!)
            }
        }
    }

    var lastSegment: Segment? {
        get { return tracks.last?.segments.last }
        set {
            if newValue == nil || tracks.isEmpty {
                parseState = .error
            } else {
                tracks[tracks.count - 1].segments.append(newValue!)
            }
        }
    }

    var lastPoint: Point? {
        get { return tracks.last?.segments.last?.points.last }
        set {
            let trackIx = tracks.count - 1
            if newValue == nil ||
               tracks.isEmpty ||
               tracks[trackIx].segments.isEmpty {
                parseState = .error
            } else {
                let segmentIx = tracks[trackIx].segments.count - 1
                tracks[trackIx].segments[segmentIx].points.append(newValue!)
            }
        }
    }

    /// init from contents of a URL
    init(contentsOf url: URL) throws {
        guard let parser = XMLParser(contentsOf: url) else {
            throw GpxParseError.gpxOpenError
        }
        self.parser = parser
        super.init()
        self.parser.delegate = self
    }

    /// parse the XML in the URL associated with this object
    /// - Returns: true if the file was parsed without error

    func parse() throws {
        if parser.parse() && parseState != .error {
            var segments = 0
            var points = 0
            for track in tracks {
                segments += track.segments.count
                for segment in track.segments {
                    points += segment.points.count
                }
            }
            if points == 0 {
                throw GpxParseError.gpxNoPoints
            }
        } else {
            throw GpxParseError.gpxParsingError
        }
    }

    /// Search for the last point in the track log with a timestamp <= the
    /// timestamp of a given image.
    ///
    /// - Parameter image: the image to update
    /// - Parameter found: A closure envoked if a point is found
    ///

//    func search(image: ImageData,
//                found: (Coord) -> ()) {
//        let imageTime = image.intervalFromEpoch(with: Self.timeZone)
//        var lastPoint: Point?
//
//        // search every track for the last point with a timestamp <= the
//        // image timestamp.   The location of the found point (if any)
//        // will be used as the image location.  All tracks must be searched
//        // as tracks are not sorted
//
//        tracks.forEach {
//            track in
//            for segment in track.segments {
//                let possiblePoints = segment.points.prefix {
//                    $0.timeFromEpoch <= imageTime
//                }
//                if let segmentLast = possiblePoints.last {
//                    if lastPoint == nil {
//                        lastPoint = segmentLast
//                    } else if segmentLast.timeFromEpoch > lastPoint!.timeFromEpoch {
//                        lastPoint = segmentLast
//                    }
//
//                    // if this wasn't the last point in a segment we've
//                    // found the last point in the current track.  Don't
//                    // bother checking any remaining segments.
//
//                    if possiblePoints.count != segment.points.count {
//                        break
//                    }
//                }
//            }
//        }
//        if let last = lastPoint {
//            found(Coord(latitude: last.lat, longitude: last.lon))
//        }
//    }
}

extension Gpx: XMLParserDelegate {

    /// process the start of an element according to the current state.
    /// Most elements are ignored

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        switch parseState {
        case .none:
            // ignore everything until the trk element
            if elementName == "trk" {
                lastTrack = Track()
                parseState = .trk
            }
        case .trk:
            switch elementName {
            case "trk":
                // nested tracks not allowed
                parseState = .error
            case "trkseg":
                if lastTrack != nil {
                    lastSegment = Segment()
                    parseState = .trkSeg
                } else {
                    parseState = .error
                }
            case "trkpt":
                // trkpt must be in a trkseg
                parseState = .error
            default:
                // ignore everything else
                break
            }
        case .trkSeg:
            switch elementName {
            case "trk", "trkseg":
                // nested tracks and track segments not allowed
                parseState = .error
            case "trkpt":
                if lastSegment != nil {
                    if let latString = attributeDict["lat"],
                       let lat = Double(latString),
                       let lonString = attributeDict["lon"],
                       let lon = Double(lonString) {
                        lastPoint = Point(lat: lat, lon: lon, ele: nil, time: "")
                        parseState = .trkPt
                    } else {
                        parseState = .error
                    }
                } else {
                    parseState = .error
                }
            default:
                // ignore everything else
                break
            }
        case .trkPt:
            switch elementName {
            case "trk", "trkseg", "trkpt":
                // nested tracks, track segments, and track points not allowed
                parseState = .error
            case "ele":
                parseState = .ele
            case "time":
                parseState = .time
            default:
                // ignore everything else
                break
            }
        case .ele, .time, .error:
            break
        }
    }

    /// at the end of the elements we care about wind back the state

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "ele":
            if parseState == .ele {
                parseState = .trkPt
            }
        case "time":
            if parseState == .time {
                parseState = .trkPt
            }
        case "trkpt":
            if parseState == .trkPt {
                parseState = .trkSeg
            } else {
                parseState = .error
            }
        case "trkseg":
            if parseState == .trkSeg {
                parseState = .trk
            } else {
                parseState = .error
            }
        case "trk":
            if parseState == .trk {
                parseState = .none;
            } else {
                parseState = .error
            }
        default:
            break
        }
    }

    /// process the string of characters for the current element.  This
    /// program only cares about characters for the time element and the ele element

    func parser(_ parser: XMLParser,
                foundCharacters string: String) {
        switch parseState {
        case .ele, .time:
            // find the latest point
            let trackIx = tracks.count - 1
            if !tracks.isEmpty && !tracks[trackIx].segments.isEmpty {
                let segmentIx = tracks[trackIx].segments.count - 1
                if !tracks[trackIx].segments[segmentIx].points.isEmpty {
                    let pointIx = tracks[trackIx].segments[segmentIx].points.count - 1
                    if parseState == .ele {
                        tracks[trackIx].segments[segmentIx].points[pointIx].ele = Double(string)
                    } else {
                        tracks[trackIx].segments[segmentIx].points[pointIx].time += string
                    }
                    return
                }
                parseState = .error
            }
        default:
            break
        }
    }
}
