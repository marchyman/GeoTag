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

public func addURLsInFolder(URL: NSURL, inout toURLs URLs: [NSURL]) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var dir: ObjCBool = false
    if fileManager.fileExistsAtPath(URL.path!, isDirectory: &dir) && dir {
        guard let urlEnumerator =
            fileManager.enumeratorAtURL(URL,
                                        includingPropertiesForKeys: [NSURLIsDirectoryKey],
                                        options: .SkipsHiddenFiles,
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
            URLs.append(fileURL)
        }
        return true
    }
    return false
}

