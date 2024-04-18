//
//  Gpx.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/22/18.
//

import Foundation

/// GPX file processing
///
/// An instance of a Gpx is created whenever a gpx file is opened.  The file is parsed and the
/// instance fully populated with Track information by the URLToImageHelper Actor running in a Task.
/// Once the instance is fully populated it is never changed.  This occurs before the task ends.
/// For this reason it is safe to pass fully filed out instances between Actors and the class is marked
/// as @unchecked Sendable.

final class Gpx: NSObject {
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
    struct Point: Equatable {
        let lat: Double
        let lon: Double
        var ele: Double?
        var time: String
        var timeFromEpoch: TimeInterval
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

}

extension Gpx: XMLParserDelegate {

    /// process the start of an element according to the current state.
    /// Most elements are ignored

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
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
                        lastPoint = Point(lat: lat, lon: lon, ele: nil, time: "", timeFromEpoch: 0)
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
                // find the latest point and update its timeFromEpoch
                let trackIx = tracks.count - 1
                if !tracks.isEmpty && !tracks[trackIx].segments.isEmpty {
                    let segmentIx = tracks[trackIx].segments.count - 1
                    if !tracks[trackIx].segments[segmentIx].points.isEmpty {
                        let pointIx = tracks[trackIx].segments[segmentIx].points.count - 1
                        let trimmedTime = tracks[trackIx]
                            .segments[segmentIx]
                            .points[pointIx]
                            .time
                            .replacingOccurrences(of: "\\.\\d+",
                                                  with: "",
                                                  options: .regularExpression)
                        if let convertedTime = Gpx.pointTimeFormat.date(from: trimmedTime) {
                            tracks[trackIx]
                                .segments[segmentIx]
                                .points[pointIx]
                                .timeFromEpoch = convertedTime.timeIntervalSince1970
                        } else {
                            tracks[trackIx]
                                .segments[segmentIx]
                                .points[pointIx]
                                .timeFromEpoch = 0
                        }
                    }
                }
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
                parseState = .none
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
