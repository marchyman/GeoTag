// Exiftool package tests

import SwiftUI
import Testing

@testable import Exiftool

struct ExiftoolTests {
    // read the version of the embedded exiftool
    // verifies the tool is part of the bundle and can be
    // accessed by package code.

    @Test func exiftoolVersion() async throws {
        let version = try #require(try Exiftool.helper.version())
        print("Using Exiftool version: \(version)")
    }

    // Check for writable and not writable file types where
    // writable is defined as can be read by core graphics
    // and updated by exiftool. There are file types that could
    // be written by exiftool but are flagged as not writable
    // because core graphics can't read file metadata.

    @Test func exiftoolNotWritableType() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "nowrite",
                              withExtension: "typ")
        )
        #expect(!Exiftool.helper.fileTypeIsWritable(for: url))
    }

    @Test func exiftoolWritableType() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG")
        )
        #expect(Exiftool.helper.fileTypeIsWritable(for: url))
    }
}
