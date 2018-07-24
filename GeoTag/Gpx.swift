//
//  Gpx.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/22/18.
//  Copyright © 2018 Marco S Hyman. All rights reserved.
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
    // parser states
    enum ParseState {
        case none
        case trk
        case trkSeg
        case trkPt
        case time
        case error
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
    init?(
        contentsOf url: URL
    ) {
        guard let parser = XMLParser(contentsOf: url) else {
            print("Gpx init failed")
            return nil
        }
        self.parser = parser
        super.init()
        self.parser.delegate = self
    }

    /// parse the XML from the give
    func parse(
    ) -> Bool {
        if parser.parse() && parseState != .error {
            print("\(tracks.count) tracks")
            var segments = 0
            var points = 0
            for track in tracks {
                segments += track.segments.count
                for segment in track.segments {
                    points += segment.points.count
                }
            }
            print("\(segments) segments")
            print("\(points) points")
            print("XML file parsed correctly")
            return true
        }
        print("XML Parse error \(String(describing: parser.parserError))")
        return false
    }

    /// Update the location of a given image from data in the track log.
    /// The location of the last track point with a timestamp less than or equal
    /// to the image is used.
    func update(
        image: ImageData,
        row: Int,
        doUpdate: (Int, Bool,Coord, Bool) -> Void
    ) {
        let imageTime = image.dateFromEpoch
        print("Image date: \(image.date) (\(imageTime))")
        var lastPoint: Point?

        for track in tracks {
            for segment in track.segments {
                for point in segment.points {
                    if point.timeFromEpoch < imageTime {
                        lastPoint = point
                    } else {
                        if let last = lastPoint {
                            print("Update locn row \(row)")
                            doUpdate(row, true, Coord(latitude: last.lat,
                                                      longitude: last.lon), true)
                            return
                        }
                    }
                }
            }
        }
        if let last = lastPoint {
            doUpdate(row, true, Coord(latitude: last.lat,
                                      longitude: last.lon), true)
        }
    }
}

extension Gpx: XMLParserDelegate {
    /// process the start of an element according to the current state.
    /// Most elements are ignored
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
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
                    unexpected(error: nil,
                               "Internal error! GPX file will be ignored")
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
                        lastPoint = Point(lat: lat, lon: lon, time: "")
                        parseState = .trkPt
                    } else {
                        parseState = .error
                    }
                } else {
                    unexpected(error: nil,
                               "Internal error! GPX file will be ignored")
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
            case "time":
                parseState = .time
            default:
                // ignore everything else
                break
            }
        case .time, .error:
            break
        }
    }

    /// at the end of the elements we care about wind back the state
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
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
    /// program only cares about characters for the time element
    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if parseState == .time {
            // find the latest point
            let trackIx = tracks.count - 1
            if !tracks.isEmpty && !tracks[trackIx].segments.isEmpty {
                let segmentIx = tracks[trackIx].segments.count - 1
                if !tracks[trackIx].segments[segmentIx].points.isEmpty {
                    let pointIx = tracks[trackIx].segments[segmentIx].points.count - 1
                    tracks[trackIx].segments[segmentIx].points[pointIx].time += string
                    return
                }
            }
            parseState = .error
        }
    }
}

/// A track consists of one or more track segments
struct Track {
    var segments = [Segment]()
}

/// A track segment consists of one or more track points
struct Segment {
    var points = [Point]()
}

/// date formater for track point timestamps
@available(OSX 10.12, *)
let pointTimeFormat = ISO8601DateFormatter()

/// Track points contain (at least) a latitude, longitude, and timestamp
struct Point {
    let lat: Double
    let lon: Double
    var time: String
    var timeFromEpoch: TimeInterval {
        if #available(OSX 10.12, *) {
            if let convertedTime = pointTimeFormat.date(from: time) {
                return convertedTime.timeIntervalSince1970
            }
        }
        return 0
    }
}

