//
//  ImageModelHelpers.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/18/22.
//

import Foundation

// Static helper functions used when initializing an ImageModel
// instance. They can't be member functions as they are called before the
// instance is fully initialized.  They need not be member functions as
// they don't access ImageModel data.

extension ImageModel {

    // Link the given fileURL to the app sandbox, create a unique name if necessary

    static func createSandboxUrl(fileURL: URL) throws -> URL {
        var sandboxURL: URL

        let fileManager = FileManager.default
        let docDir = try fileManager.url(for: .documentDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true)
        sandboxURL = docDir.appendingPathComponent(fileURL.lastPathComponent)

        // if sandboxURL already exists modify the name until it doesn't
        var fileNumber = 1
        while fileManager.fileExists(atPath: (sandboxURL.path)) {
            var newName = fileURL.lastPathComponent
            let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            sandboxURL = docDir.appendingPathComponent(newName)
        }

        // fileExistsAtPath will return false when a symbolic link
        // exists but does not point to a valid file.  Handle that
        // situation to avoid a crash by deleting any stale link
        // that may be present before trying to create a new link.
        try? fileManager.removeItem(at: sandboxURL)
        try fileManager.createSymbolicLink(at: sandboxURL,
                                           withDestinationURL: fileURL)
        return sandboxURL
    }

    // Create a link for a sidecar file matching the image file.  The link
    // is created even if there is no sidecar file as one may be created,
    // later.  Add a file presenter to allow us to write to the XMP file even
    // when only the image file was opened.

    static func createSandboxXmpURL(fileURL: URL,
                                    xmpURL: URL,
                                    xmpFile: XmpFile) throws -> URL? {
        // don't look for a sidecar file for a sidecar file
        guard fileURL.pathExtension.lowercased() != xmpExtension else {
            return nil
        }

        let sandboxXmpURL = xmpFile.presentedItemURL
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: sandboxXmpURL!)
        try fileManager.createSymbolicLink(at: sandboxXmpURL!,
                                           withDestinationURL: xmpURL)

        return sandboxXmpURL
    }
}
