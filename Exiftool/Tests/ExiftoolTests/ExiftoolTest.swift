// Exiftool package tests

import Metadata
import SwiftUI
import Testing

@testable import Exiftool

struct ExiftoolTests {

    // return the url of a folder in the standard temporaryDirectory
    // used to hold files that will be modified by tests
    // if an image url is passed to the function copy the image
    // into the folder before returning

    func makeTestFolder(andCopy url: URL? = nil) throws -> URL {
        let testFolder =
            URL.temporaryDirectory.appending(components: UUID().uuidString)

        try FileManager.default.createDirectory(at: testFolder,
                                                withIntermediateDirectories: true)
        if let url {
            let name = url.lastPathComponent
            let copy = testFolder.appending(component: name)
            try FileManager.default.copyItem(at: url, to: copy)
        }
        return testFolder
    }

    // read the version of the embedded exiftool
    // verifies the tool is part of the bundle and can be
    // accessed by package code.

    @Test func getVersion() async throws {
        let version = try #require(try Exiftool.helper.version())
        print("Using Exiftool version: \(version)")
    }

    // Check for writable and not writable file types where
    // writable is defined as can be read by core graphics
    // and updated by exiftool. There are file types that could
    // be written by exiftool but are flagged as not writable
    // because core graphics can't read file metadata.

    @Test func checkNotWritableType() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "nowrite",
                              withExtension: "typ")
        )
        #expect(!Exiftool.helper.fileTypeIsWritable(for: url))
    }

    @Test func checkWritableType() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG")
        )
        #expect(Exiftool.helper.fileTypeIsWritable(for: url))
    }

    // Copy a test image to the documents folder and create an
    // xmp sidecar file from the image

    @Test func createSidecar() async throws {
        // setup
        let testImage = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG")
        )
        let testFolder = try makeTestFolder(andCopy: testImage)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }

        // now attempt to create a sidecar file from the copied
        // image. Verify a sidecar file exists.

        let name = testImage.lastPathComponent
        let copy = testFolder.appending(component: name)
        Exiftool.helper.makeSidecar(from: copy)
        let sidecar = copy.deletingPathExtension()
            .appendingPathExtension(Metadata.xmpExtension)
        #expect(FileManager.default.fileExists(atPath: sidecar.path))
    }

    // Verify data extracted from a created sidecar file.

    @Test func verifySidecar() async throws {
        // setup
        let testImage = try #require(
            Bundle.module.url(forResource: "IMG_5654",
                              withExtension: "HEIC")
        )
        let testFolder = try makeTestFolder(andCopy: testImage)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }
        let name = testImage.lastPathComponent
        let copy = testFolder.appending(component: name)
        Exiftool.helper.makeSidecar(from: copy)
        let sidecar = copy.deletingPathExtension()
            .appendingPathExtension(Metadata.xmpExtension)
        #expect(FileManager.default.fileExists(atPath: sidecar.path))

        // Extract needed data from the created sidecar file

        let metadata = Exiftool.helper.metadata(from: sidecar)
        #expect(metadata.dateTimeCreated == "2025:12:03 16:25:49")
        #expect(metadata.location?.latitude == 37.51878611116667)
        #expect(metadata.location?.longitude == -122.34516111116666)
        #expect(metadata.elevation == nil)
        #expect(metadata.city == nil)
        #expect(metadata.state == nil)
        #expect(metadata.country == nil)
        #expect(metadata.countryCode == nil)
    }

    // Verify the data from the created sidecar is the same as
    // a known good sidecar file.

    @Test func verifySidecarSame() async throws {
        // setup
        let testImage = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG")
        )
        let testFolder = try makeTestFolder(andCopy: testImage)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }
        let name = testImage.lastPathComponent
        let copy = testFolder.appending(component: name)
        Exiftool.helper.makeSidecar(from: copy)
        let sidecar = copy.deletingPathExtension()
            .appendingPathExtension(Metadata.xmpExtension)
        #expect(FileManager.default.fileExists(atPath: sidecar.path))

        // Extract needed data from the created sidecar file

        let newData = Exiftool.helper.metadata(from: sidecar)

        // Extract the same data from an existing sidecar file

        let oldSidecar = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "xmp")
        )
        let oldData = Exiftool.helper.metadata(from: oldSidecar)

        #expect(newData == oldData)
    }
}
