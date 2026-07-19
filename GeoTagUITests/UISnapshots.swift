import Foundation
import XCTest

// put snapshot releated items in their own namespace

struct Snapshots {
    enum SnapshotError: Error {
        case missingPath
    }

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

    static func baseImage(from name: String) -> String? {
        // path to known good image
        guard let snapshotPath =
            ProcessInfo.processInfo.environment["Snapshots"] else {
                XCTFail("Snapshots path not in environment")
                return nil
            }
        let path = snapshotPath + "/" + name
        guard FileManager.default.isReadableFile(atPath: path) else {
            XCTFail("\(path) not readable")
            return nil
        }
        return path
    }

    static func diffImage(name: String) throws {
        guard let good = baseImage(from: name) else { return }
        let test = saveImageURL(from: name)
        guard FileManager.default.isReadableFile(atPath: test.path()) else {
            XCTFail("\(test.path()) not readable")
            return
        }

        let odiff = Process()
        let pipe = Pipe()
        let err = Pipe()
        odiff.standardOutput = pipe
        odiff.standardError = err
        odiff.executableURL = URL(filePath: "/usr/local/bin/odiff")
        odiff.arguments = [good, test.path, "--aa", "-t", "0.8"]
        try odiff.run()
        odiff.waitUntilExit()
        if odiff.terminationStatus != 0 {
            XCTFail("""
                Image mismatch:
                - good: \(good)
                - test: \(test.path)")

                Use the following command to look at the differences
                $ odiff <good> <test> diffs.png --aa -t 0.8
                $ open diffs.png
                """)
        }
    }
}
