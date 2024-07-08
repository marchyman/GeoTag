//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation
import Testing
@testable import GeoTag

struct GpxTests {

    @Test func gpxParse() async throws {
        if let gpxPath = ProcessInfo.processInfo.environment["GpxPath"] {
            let gpxUrl = URL(fileURLWithPath: "\(gpxPath)/TestTrack.GPX")
            let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
            var tracks = trackLog.tracks.count
            var segments = trackLog.tracks.reduce(0) { $0 + $1.segments.count }
            var points = trackLog.tracks.reduce(0) {
                $0 + $1.segments.reduce(0) { $0 + $1.points.count }
            }
            print("\(tracks) tracks, \(segments) segments, \(points) points")
            return
        }
        try #require(Bool(false),
                     "GpxPath must be set in the run time environment")
    }

    @Test func gpxParseNoTrack() async throws {
        if let gpxPath = ProcessInfo.processInfo.environment["GpxPath"] {
            let gpxUrl = URL(fileURLWithPath: "\(gpxPath)/NoTrack.GPX")
            #expect(throws: Error.self) {
                let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
            }
            return
        }
        try #require(Bool(false),
                     "GpxPath must be set in the run time environment")
    }

    @Test func gpxParseBadTrack() async throws {
        if let gpxPath = ProcessInfo.processInfo.environment["GpxPath"] {
            let gpxUrl = URL(fileURLWithPath: "\(gpxPath)/BadTrack.GPX")
            #expect(throws: Error.self) {
                let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
            }
            return
        }
        try #require(Bool(false),
                     "GpxPath must be set in the run time environment")
    }
}
