//
//  CoordsTests.swift
//  GeoTagTests
//
//  Created by Marco S Hyman on 2025-05-16.
//

import SwiftUI
import Testing
@testable import GeoTag

// these tests must be serialized as they depend upon AppStorage being in the
// state set up by the individual tests

@Suite(.serialized)
struct CoordsFormatTests {

    @Test func coordFormatLatitude0Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .deg
        #expect(coord.formatted(.latitude) == " 0.000000")
    }

    @Test func coordFormatLatitude0DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .degMin
        #expect(coord.formatted(.latitude) == "0° 0.000000' N")
    }

    @Test func coordFormatLatitude0DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.latitude) == "0° 0' 0.00\" N")
    }

    @Test func coordFormatLongitude0Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .deg
        #expect(coord.formatted(.longitude) == " 0.000000")
    }

    @Test func coordFormatLongitude0DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .degMin
        #expect(coord.formatted(.longitude) == "0° 0.000000' E")
    }

    @Test func coordFormatLongitude0DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 0.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.longitude) == "0° 0' 0.00\" E")
    }

    @Test func coordFormatLatitude90Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 90.0, longitude: 0.0)
        coordFormat = .deg
        #expect(coord.formatted(.latitude) == " 90.000000")
    }

    @Test func coordFormatLatitude90DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 90.0, longitude: 0.0)
        coordFormat = .degMin
        #expect(coord.formatted(.latitude) == "90° 0.000000' N")
    }

    @Test func coordFormatLatitude90DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 90.0, longitude: 0.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.latitude) == "90° 0' 0.00\" N")
    }

    @Test func coordFormatLongitude180Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 180.0)
        coordFormat = .deg
        #expect(coord.formatted(.longitude) == " 180.000000")
    }

    @Test func coordFormatLongitude180DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 180.0)
        coordFormat = .degMin
        #expect(coord.formatted(.longitude) == "180° 0.000000' E")
    }

    @Test func coordFormatLongitude180DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: 180.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.longitude) == "180° 0' 0.00\" E")
    }

    @Test func coordFormatLatitude_90Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: -90.0, longitude: 0.0)
        coordFormat = .deg
        #expect(coord.formatted(.latitude) == "-90.000000")
    }

    @Test func coordFormatLatitude_90DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: -90.0, longitude: 0.0)
        coordFormat = .degMin
        #expect(coord.formatted(.latitude) == "90° 0.000000' S")
    }

    @Test func coordFormatLatitude_90DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: -90.0, longitude: 0.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.latitude) == "90° 0' 0.00\" S")
    }

    @Test func coordFormatLongitude_180Deg() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: -180.0)
        coordFormat = .deg
        #expect(coord.formatted(.longitude) == "-180.000000")
    }

    @Test func coordFormatLongitude_180DegMin() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: -180.0)
        coordFormat = .degMin
        #expect(coord.formatted(.longitude) == "180° 0.000000' W")
    }

    @Test func coordFormatLongitude_180DegMinSec() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 0.0, longitude: -180.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.longitude) == "180° 0' 0.00\" W")
    }

    // the format code does not validate its input. It will format what
    // you give it to the best of its ability
    @Test func coordFormatInvalid() async throws {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
        let coord: Coords = .init(latitude: 91.0, longitude: -181.0)
        coordFormat = .degMinSec
        #expect(coord.formatted(.latitude) == "91° 0' 0.00\" N")
        #expect(coord.formatted(.longitude) == "181° 0' 0.00\" W")
    }
}

struct CoordsStringTests {

    struct Args {
        let str: String
        let val: Double?
        init(_ str: String, _ val: Double?) {
            self.str = str
            self.val = val
        }
    }

    @Test(arguments: [
        Args("", nil),
        Args("0", 0.0),
        Args("45.5", 45.5),
        Args("90", 90.0),
        Args("90° S", -90.0),
        Args("-90°", -90.0),
        Args("-90° S", nil),
        Args("0° 0.0000' N", 0.0),
        Args("0° 0.0000' S", 0.0),
        Args("0° 0' 0.00\" N", 0.0),
        Args("0° 0' 0.00\" S", 0.0),
        Args("0° 0' 0.00\" E", nil),
        Args("0 0 0 S X", nil),
        Args("45 17 13.24 n", 45.287011111111106),
        Args("90° 0.000000'", 90.0),
        Args("90° 0.000000' 0.00\" N", 90.0),
        Args("90° 0.000000' 0.00\" s", -90.0),
        Args("-90° 0.000000' 0.00\"", -90.0),
        Args("90° 0.00000' 0.01\"", nil),
        Args("91", nil)
    ])
    func coordLatStringDeg(args: Args) async throws {
        #expect(args.str.validateLatitude() == args.val)
    }

    @Test(arguments: [
        Args("", nil),
        Args("0", 0.0),
        Args("45.5", 45.5),
        Args("135.5", 135.5),
        Args("90", 90.0),
        Args("90 E", 90.0),
        Args("90° W", -90.0),
        Args("-90°", -90.0),
        Args("-90° W", nil),
        Args("180", 180.0),
        Args("180° W", -180.0),
        Args("-180°", -180.0),
        Args("-180° W", nil),
        Args("0° 0.0000' E", 0.0),
        Args("0° 0.0000' W", 0.0),
        Args("0° 0' 0.00\" E", 0.0),
        Args("0° 0' 0.00\" W", 0.0),
        Args("0° 0' 0.00\" S", nil),
        Args("0 0 0 W X", nil),
        Args("45 17 13.24 e", 45.287011111111106),
        Args("180° 0.000000'", 180.0),
        Args("180° 0.000000' 0.00\" e", 180.0),
        Args("180° 0.000000' 0.00\" w", -180.0),
        Args("-180° 0.000000' 0.00\"", -180.0),
        Args("180° 0.00000' 0.01\"", nil),
        Args("181", nil)
    ])
    func coordLonStringDeg(args: Args) async throws {
        #expect(args.str.validateLongitude() == args.val)
    }
}
