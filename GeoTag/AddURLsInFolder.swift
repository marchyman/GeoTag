//
//  FilesInFolder.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/16/15.
//  Copyright (c) 2015 Marco S Hyman, CC-BY-NC
//

import Foundation

/// enumerate the files in a folder adding URLs for all files found to an array
/// - Parameter url: a URL of the folder to enumerate
/// - Parameter toUrls: the array to add the url of found files
/// - Returns: true if the URL was a folder, false otherwise
///
/// Non-hidden files are added to the inout toUrls parameter. Hidden files
/// and internal folders are not added to the array.  Internal folders are
/// enumerated.

public func addUrlsInFolder(url: URL, toUrls urls: inout [URL]) -> Bool {
    let fileManager = FileManager.default
    var dir = ObjCBool(false)
    if fileManager.fileExists(atPath: url.path, isDirectory: &dir) && dir.boolValue {
        guard let urlEnumerator =
            fileManager.enumerator(at: url,
                                   includingPropertiesForKeys: [.isDirectoryKey],
                                   options: [.skipsHiddenFiles],
                                   errorHandler: nil) else { return false }
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            guard
                let resources =
                    try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]),
                let directory = resources.isDirectory
                else { continue }
            if !directory {
                urls.append(fileUrl)
            }
        }
        return true
    }
    return false
}

