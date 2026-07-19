import Foundation
import XCTest

// put snapshot releated items in their own namespace

struct Snapshots {
    static let imageSaveLocation = "GeoTag/Snapshots/"

    static func saveImageURL(from name: String) -> URL {
        return URL.temporaryDirectory
                  .appending(path: imageSaveLocation)
                  .appendingPathComponent(name)
    }

    static func saveImage(_ data: Data, as name: String) throws {
        let saveFolder = URL.temporaryDirectory
                            .appending(path: imageSaveLocation)
        if !FileManager.default.fileExists(atPath: saveFolder.path) {
            try FileManager.default.createDirectory(at: saveFolder,
                                                    withIntermediateDirectories: true)
        }
        let saveURL = saveFolder.appendingPathComponent(name)
        try data.write(to: saveURL)
        print("saved \(name) to \(saveURL.path)")
    }

    static func diffImage(good baseImage: String, test testImage: String) throws {
        let odiff = Process()
        let pipe = Pipe()
        let err = Pipe()
        odiff.standardOutput = pipe
        odiff.standardError = err
        odiff.executableURL = URL(filePath: "/usr/local/bin/odiff")
        odiff.arguments = [baseImage, testImage, "--aa", "-t", "0.8"]
        try odiff.run()
        odiff.waitUntilExit()
        if odiff.terminationStatus != 0 {
            XCTFail("""
                Image mismatch:
                - good: \(baseImage)
                - test: \(testImage)")

                Use the following command to look at the differences
                $ odiff <good> <test> diffs.png --aa -t 0.8
                $ open diffs.png
                """)
        }
    }
}
