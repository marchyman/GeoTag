//
//  FilesInFolder.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/16/15.
//  Copyright (c) 2015 Marco S Hyman, CC-BY-NC
//

import Foundation

/// enumerate the files in a folder adding URLs for all files found to an array
/// - Parameter URL: a URL of the folder to enumerate
/// - Parameter toURLs: the array to add the URL of found files
/// - Returns: true if the URL was a folder, false otherwise
///
/// Non-hidden files are added to the inout toURLs parameter. Hidden files
/// and internal folders are not added to the array.  Internal folders are
/// enumerated.

public func addURLsInFolder(url: NSURL, toUrls urls: inout [NSURL]) -> Bool {
    let fileManager = NSFileManager.default()
    var dir: ObjCBool = false
    if fileManager.fileExists(atPath: url.path!, isDirectory: &dir) && dir {
        guard let urlEnumerator =
            fileManager.enumerator(at: url,
                                   includingPropertiesForKeys: [NSURLIsDirectoryKey],
                                   options: .skipsHiddenFiles,
                                   errorHandler: nil) else { return false }
        while let fileURL = urlEnumerator.nextObject() as? NSURL {
            var resource: AnyObject?
            do {
                try fileURL.getResourceValue(&resource,
                                             forKey: NSURLIsDirectoryKey)
                if resource as? Int == 1 {
                    continue
                }
            } catch {
                // assume the fileURL is not a folder
            }
            urls.append(fileURL)
        }
        return true
    }
    return false
}

