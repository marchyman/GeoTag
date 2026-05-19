import Foundation
import ImageData
import OSLog
import SwiftUI
import UDF

// for each jpg/jpeg file in the table of images find any matching
// raw file. Link the two together by ID when found. If paired jpegs
// are disabled remove any original metadata which marks the image
// as non-updatable

extension GeoTagState {
    mutating func linkPairedImages(_ disablePairedJpegs: Bool) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                            category: "GeoTagState")

        struct URLBase {
            let id: ImageData.ID
            let url: URL
            let base: String
        }

        let jpegBase =
            imageData.compactMap {
                if case let .image(url) = $0.metadata.source  {
                    let ext = url.pathExtension.lowercased()
                    if ext == "jpg" || ext == "jpeg" {
                        return URLBase(id: $0.id,
                                       url: url,
                                       base: url.deletingPathExtension().path)
                    }
                }
                return nil
            }
        let rawBase =
            imageData.compactMap {
                if case .image(let url) = $0.metadata.source  {
                    let ext = url.pathExtension.lowercased()
                    if ext != "jpg" && ext != "jpeg" {
                        return URLBase(id: $0.id,
                                       url: url,
                                       base: url.deletingPathExtension().path)
                    }
                }
                return nil
            }

        for jpeg in jpegBase {
            if let raw = rawBase.first(where: { $0.base == jpeg.base }) {
                logger.notice("""
                    Pairing \(jpeg.url.lastPathComponent, privacy: .public) \
                    <> \(raw.url.lastPathComponent, privacy: .public)"
                    """ )
                self[jpeg.id].pairedID = raw.id
                self[raw.id].pairedID = jpeg.id
                // disable the jpeg version if requested
                if disablePairedJpegs {
                    self[jpeg.id].original = nil
                }
            }
        }
    }
}
