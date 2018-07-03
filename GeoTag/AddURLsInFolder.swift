//
//  FilesInFolder.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/16/15.
//
// Copyright 2015-2018 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// enumerate the files in a folder adding URLs for all files found to an array
/// - Parameter url: a URL of the folder to enumerate
/// - Parameter toUrls: the array to add the url of found files
/// - Returns: true if the URL was a folder, false otherwise
///
/// Non-hidden files are added to the inout toUrls parameter. Hidden files
/// and internal folders are not added to the array.  Internal folders are
/// also enumerated.

public
func addUrlsInFolder(
    url: URL,
    toUrls urls: inout [URL]
) -> Bool {
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

