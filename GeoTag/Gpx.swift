//
//  Gpx.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/22/18.
//

import Foundation

// GPX file processing
//
// An instance of a GpxTrackLog is created by opening and parsing a GPX file.
// once an instance of a GpxTrackLog is created it is never modified.

struct GpxTrackLog: Sendable {
    var tracks = [Track]()

    init(contentsOf url: URL) throws {
        let gpxFile = try Gpx(contentsOf: url)
        tracks = try gpxFile.parse()
    }
}

// Definitions of the elements that make up a track.

extension GpxTrackLog {
    // Tracks are made up of one or more Segments.
    struct Track {
        var segments = [Segment]()
    }

    // Segments are made up of Points.
    struct Segment {
        var points = [Point]()
    }

    // points contain (at least) a latitude, longitude, and timestamp.
    struct Point: Equatable {
        let lat: Double
        let lon: Double
        var ele: Double?
        var timeFromEpoch: TimeInterval
    }
}

// A private class used to parse a GPX file.

private class Gpx: NSObject {
    // GPX Parsing errors
    enum GpxParseError: Error {
        case gpxOpenError
        case gpxNoPoints
        case gpxParsingError
    }

    // parser states
    enum ParseState {
        case none           // starting state
        case trk            // <trk> seen
        case trkSeg         // <trkseg> seen
        case trkPt          // <trkpt> seen
        case time(String)   // <time> inside of a <trkpt>
        case ele            // <ele> inside of a <trkpt>
        case error          // bad GPX file
    }

    /// date formater for track point timestamps.
    nonisolated(unsafe) static let pointTimeFormat = ISO8601DateFormatter()

    let parser: XMLParser
    var tracks = [GpxTrackLog.Track]()
    var parseState = ParseState.none

    init(contentsOf url: URL) throws {
        guard let parser = XMLParser(contentsOf: url) else {
            throw GpxParseError.gpxOpenError
        }
        self.parser = parser
        super.init()
        self.parser.delegate = self
    }
}

// GPX parse method.  The XML Parser and parse delegate do all of the work.
// The parse method returns an array of parsed tracks assuming no errors.

extension Gpx {
    func parse() throws -> [GpxTrackLog.Track] {
        if parser.parse() {
            if case .error = parseState {
                throw GpxParseError.gpxParsingError
            }

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
        return tracks
    }
}

// computed variables to access/update tracks, segments, and points
// when parsing a GPX file.

extension Gpx {

    var lastTrack: GpxTrackLog.Track? {
        get { return tracks.last }
        set {
            if newValue == nil {
                parseState = .error
            } else {
                tracks.append(newValue!)
            }
        }
    }

    var lastSegment: GpxTrackLog.Segment? {
        get { return tracks.last?.segments.last }
        set {
            if newValue == nil || tracks.isEmpty {
                parseState = .error
            } else {
                tracks[tracks.count - 1].segments.append(newValue!)
            }
        }
    }

    var lastPoint: GpxTrackLog.Point? {
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
}

// parser delegate functions

extension Gpx: XMLParserDelegate {

    // process the start of an element according to the current state.
    // Most elements are ignored

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        switch parseState {
        case .none:
            // ignore everything until the trk element
            if elementName == "trk" {
                lastTrack = GpxTrackLog.Track()
                parseState = .trk
            }
        case .trk:
            switch elementName {
            case "trk":
                // nested tracks not allowed
                parseState = .error
            case "trkseg":
                if lastTrack != nil {
                    lastSegment = GpxTrackLog.Segment()
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
                        lastPoint = GpxTrackLog.Point(lat: lat, lon: lon,
                                                      ele: nil,
                                                      timeFromEpoch: 0)
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
                parseState = .time("")
            default:
                // ignore everything else
                break
            }
        case .ele, .time, .error:
            break
        }
    }

    // at the end of the elements we care about wind back the state

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        switch elementName {
        case "ele":
            if case .ele = parseState {
                parseState = .trkPt
            } else {
                parseState = .error
            }
        case "time":
            // Time shows up in multiple spots in a GPX file. Need to be in
            // .time parseState to process.  Otherwise ignore.
            if case .time(let timestamp) = parseState {
                // convert the parsed timestamp to a date.
                let trimmedTime = timestamp
                    .replacingOccurrences(of: "\\.\\d+",
                                          with: "",
                                          options: .regularExpression)
                let convertedTime = Gpx.pointTimeFormat.date(from: trimmedTime)

                // find the latest point and update its timeFromEpoch
                let trackIx = tracks.count - 1
                if !tracks.isEmpty && !tracks[trackIx].segments.isEmpty {
                    let segmentIx = tracks[trackIx].segments.count - 1
                    if !tracks[trackIx].segments[segmentIx].points.isEmpty {
                        let pointIx = tracks[trackIx].segments[segmentIx].points.count - 1
                        if let convertedTime {
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
                parseState = .trkPt
            }
        case "trkpt":
            if case .trkPt = parseState {
                parseState = .trkSeg
            } else {
                parseState = .error
            }
        case "trkseg":
            if case .trkSeg = parseState {
                parseState = .trk
            } else {
                parseState = .error
            }
        case "trk":
            if case .trk = parseState {
                parseState = .none
            } else {
                parseState = .error
            }
        default:
            break
        }
    }

    // process the string of characters for the current element.  This
    // program only cares about characters for the time element and
    // the ele element

    func parser(_ parser: XMLParser,
                foundCharacters string: String) {
        switch parseState {
        case .ele:
            // find the latest point
            let trackIx = tracks.count - 1
            if !tracks.isEmpty && !tracks[trackIx].segments.isEmpty {
                let segmentIx = tracks[trackIx].segments.count - 1
                if !tracks[trackIx].segments[segmentIx].points.isEmpty {
                    let pointIx = tracks[trackIx].segments[segmentIx].points.count - 1
                    tracks[trackIx].segments[segmentIx].points[pointIx].ele = Double(string)
                    return
                }
                parseState = .error
            }
        case .time:
            parseState = .time(string)
        default:
            break
        }
    }
}
