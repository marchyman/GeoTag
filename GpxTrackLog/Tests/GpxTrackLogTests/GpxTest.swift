//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation
import SwiftUI
import Testing

@testable import GpxTrackLog

struct GpxTests {
    let badTrackFile = "BadTrack"
    let noTrackFile = "NoTrack"
    let testTrackFile = "TestTrack"
    let ext = "GPX"

    func testFileURL(fileName: String) throws -> URL {
        let testURL = Bundle.module.url(forResource: fileName,
                                        withExtension: ext)
        let fileURL = try #require(testURL)
        return fileURL
    }

    @Test func gpxParse() async throws {
        let gpxUrl = try testFileURL(fileName: testTrackFile)
        let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
        let tracks = trackLog.tracks.count
        let segments = trackLog.tracks.reduce(0) { $0 + $1.segments.count }
        let points = trackLog.tracks.reduce(0) {
            $0 + $1.segments.reduce(0) { $0 + $1.points.count }
        }
        print("\(tracks) tracks, \(segments) segments, \(points) points")
    }

    @Test func gpxParseNoTrack() async throws {
        let gpxUrl = try testFileURL(fileName: noTrackFile)
        #expect(throws: Error.self) {
            _ = try GpxTrackLog(contentsOf: gpxUrl)
        }
    }

    @Test func gpxParseBadTrack() async throws {
        let gpxUrl = try testFileURL(fileName: badTrackFile)
        #expect(throws: Error.self) {
            _ = try GpxTrackLog(contentsOf: gpxUrl)
        }
    }
}
