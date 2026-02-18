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
    let multiSegFile = "MultiSeg"
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
        #expect(tracks == 1)
        #expect(segments == 1)
        #expect(points == 3813)
    }

    @Test func gpxParseMultiSeg() async throws {
        let gpxUrl = try testFileURL(fileName: multiSegFile)
        let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
        let tracks = trackLog.tracks.count
        let segments = trackLog.tracks.reduce(0) { $0 + $1.segments.count }
        let points = trackLog.tracks.reduce(0) {
            $0 + $1.segments.reduce(0) { $0 + $1.points.count }
        }
        #expect(tracks == 1)
        #expect(segments == 29)
        #expect(points == 9999)
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

    @Test func gpxSearch() async throws {
        let gpxUrl = try testFileURL(fileName: multiSegFile)
        let trackLog = try GpxTrackLog(contentsOf: gpxUrl)
        let formatter = ISO8601DateFormatter()
        let insideSegment = try #require(formatter.date(from: "2008-04-19T01:20:32Z"))

        // check for point within segment
        let insideInterval = insideSegment.timeIntervalSince1970
        let _ = try #require(await trackLog.search(imageTime: insideInterval, extendedTime: 1))

        // check for point after segment
        let afterSegment = try #require(formatter.date(from: "2008-04-18T14:20:00Z"))
        let afterInterval = afterSegment.timeIntervalSince1970
        #expect(await trackLog.search(imageTime: afterInterval, extendedTime: 1) == nil)
        let _ = try #require(await trackLog.search(imageTime: afterInterval, extendedTime: 10))

        let beforeSegment = try #require(formatter.date(from: "2008-04-18T15:10:00Z"))
        let beforeInterval = beforeSegment.timeIntervalSince1970
        #expect(await trackLog.search(imageTime: beforeInterval, extendedTime: 1) == nil)
        let _ = try #require(await trackLog.search(imageTime: beforeInterval, extendedTime: 10))
    }
}
