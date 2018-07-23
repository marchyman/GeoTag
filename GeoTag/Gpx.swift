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

var gpxTracks = [Gpx]()

class Gpx: NSObject {
    enum ParseState {
        case none
        case trk
        case trkSeg
        case trkPt
        case time
    }

    var parser: XMLParser
    var tracks = [Track]()
    var parseState = ParseState.none

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
        gpxTracks.append(self)
    }

    func parse() {
        if parser.parse() {
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
        } else {
            print("XML Parse error \(String(describing: parser.parserError))")
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
            if elementName == "trk" {
                tracks.append(Track())
                parseState = .trk
            }
        case .trk:
            if elementName == "trkseg" {
                guard let track = tracks.last else { return }
                track.segments.append(Segment())
                parseState = .trkSeg
            }
        case .trkSeg:
            if elementName == "trkpt" {
                guard let segment = tracks.last?.segments.last else { return }
                if let latString = attributeDict["lat"],
                   let lat = Double(latString),
                   let lonString = attributeDict["lon"],
                   let lon = Double(lonString) {
                    segment.points.append(Point(lat: lat, lon: lon, time: ""))
                    parseState = .trkPt
                }
            }
        case .trkPt:
            if elementName == "time" {
                parseState = .time
            }
        case .time:
            break;
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
            parseState = .trkSeg;
        case "trkSeg":
            parseState = .trk;
        case "trk":
            parseState = .none;
        default:
            break
        }
    }
}

/// A track consists of one or more track segments
class Track {
    var segments = [Segment]()
}

/// A track segment consists of one or more track points
class Segment {
    var points = [Point]()
}

/// Track points contain (at least) a latitude, longitude, and timestamp
struct Point {
    let lat: Double
    let lon: Double
    var time: String
}

