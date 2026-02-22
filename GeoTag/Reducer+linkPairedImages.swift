import Foundation
import ImageData
import SwiftUI
import UDF

// for each jpg/jpeg file in the table of images find any matching
// raw file. Link the two together by ID when found. If paired jpegs
// are disabled remove any original metadata which marks the image
// as non-updatable

extension GeoTagReducer {
    func linkPairedImages(_ state: inout GeoTagState) {
        logger.notice(#function)

        struct URLBase {
            let id: ImageData.ID
            let url: URL
            let base: String
        }

        @AppStorage(SettingsView.disablePairedJpegsKey) var disablePairedJpegs = false

        let jpegBase =
            state.imageData.compactMap {
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
            state.imageData.compactMap {
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
                logger.notice(
                    "Pairing \(jpeg.url, privacy: .public) <> \(raw.url, privacy: .public)"
                )
                state[jpeg.id].pairedID = raw.id
                state[raw.id].pairedID = jpeg.id
                // disable the jpeg version if requested
                if disablePairedJpegs {
                    state[jpeg.id].original = nil
                }
            }
        }
    }
}
