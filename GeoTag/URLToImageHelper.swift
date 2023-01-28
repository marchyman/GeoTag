//
//  URLToImageHelper.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/30/22.
//

import Foundation

actor URLToImageHelper {
    var gpxTracks = [Gpx]()
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()
    var processedURLs = Set<URL>()
    var duplicateImages = false
    var gpxFiles = false

    var sheetStack = [ContentViewModel.SheetInfo]()

    init(knownImages: [ImageModel]) {
        processedURLs = Set(knownImages.map {$0.fileURL })
    }

    // see if the URL refers to an image, a gpx file, or other.  Instances
    // of ImageModel that may be created are returned immediately.  Tracks
    // and other info are stored for the life of the helper.

    func urlToImage(url: URL) -> ImageModel? {
        if url.pathExtension.lowercased() == "gpx" {
            parseGpxFile(url)
        } else if processedURLs.contains(url) {
            // only one duplicate image sheet regardless the number of dups
            if !duplicateImages {
                sheetStack.append(ContentViewModel.SheetInfo(sheetType: .duplicateImageSheet,
                                                             sheetError: nil,
                                                             sheetMessage: nil))
                duplicateImages.toggle()
            }
        } else {
            processedURLs.insert(url)
            do {
                return try ImageModel(imageURL: url)
            } catch let error as NSError {
                sheetStack.append(ContentViewModel.SheetInfo(sheetType: .unexpectedErrorSheet,
                                                             sheetError: error,
                                                             sheetMessage: "Failed to open file \(url.path)"))
            }
        }
        return nil
    }

    /// Parse the given url to see if it is a valid gpx file.  A valid gpx file
    /// ends in .gpx and can be parsed by the GPX parser without error.
    ///
    /// - Parameters:
    ///   - url: URL of file to parse
    /// - Returns: true if file is a gpx file, otherwise false

    func parseGpxFile(_ url: URL) {
        do {
            let gpx = try Gpx(contentsOf: url)
            try gpx.parse()
            gpxTracks.append(gpx)
            gpxGoodFileNames.append(url.path)
        } catch {
            gpxBadFileNames.append(url.path)
        }
        // only need one sheet when a GPX file is added.
        if !gpxFiles {
            gpxFiles.toggle()
            sheetStack.append(ContentViewModel.SheetInfo(sheetType: .gpxFileNameSheet,
                                                         sheetError: nil,
                                                         sheetMessage: nil))
        }
    }

}
