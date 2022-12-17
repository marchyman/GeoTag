//
//  ImageModelImage.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/16/22.
//

import Foundation
import AppKit
import SwiftUI

// Create a static instance of an ImageModel for View previews.  The image
// is named TestImage in the app asset catalog.

extension ImageModel {
    static var testImage: ImageModel {
        let imageURL = createLocalUrl(forImageNamed: "TestImage")
        let image = try? ImageModel(imageURL: imageURL!)
        return image!
    }
}

func createLocalUrl(forImageNamed name: String) -> URL? {
    let fileManager = FileManager.default
    guard let cacheDirectory =
            try? fileManager.url(for: .cachesDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true) else { return nil }

    let url = cacheDirectory.appendingPathComponent("\(name).jpg")

    // url points to an image in the cache.  If the referenced image doesn't
    // exist then copy it to the cache from our asset catalog.

    guard fileManager.fileExists(atPath: url.path) else {
        guard
            let image = NSImage(named: name),
            image.save(as: url)
        else { return nil }

        return url
    }

    return url
}

extension NSImage {
    func save(as fileURL: URL,
              fileType: NSBitmapImageRep.FileType = .jpeg) -> Bool {
        let properties = [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]

        guard
            let imageData = tiffRepresentation,
            let imageRep = NSBitmapImageRep(data: imageData),
            let fileData = imageRep.representation(using: fileType,
                                                   properties: properties)
        else { return false }

        do { try fileData.write(to: fileURL) }
        catch { return false }
        return true
    }
}

