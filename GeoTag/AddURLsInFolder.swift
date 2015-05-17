//
//  FilesInFolder.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/16/15.
//  Copyright (c) 2015 Marco S Hyman. All rights reserved.
//

import Foundation

/*
 * If url is a folder add all the URLs in the folder to toURLs and
 * return true.  Return false if URL is not a directory
 */
func addURLsInFolder(URL: NSURL, inout toURLs URLs: [NSURL]) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var dir: ObjCBool = false
    if fileManager.fileExistsAtPath(URL.path!, isDirectory: &dir) && dir {
        if let urlEnumerator =
            fileManager.enumeratorAtURL(URL,
                                        includingPropertiesForKeys: [NSURLIsDirectoryKey],
                                        options: .SkipsHiddenFiles,
                                        errorHandler: nil) {
            while let fileURL = urlEnumerator.nextObject() as? NSURL {
                var resource: AnyObject?
                if fileURL.getResourceValue(&resource,
                                            forKey: NSURLIsDirectoryKey,
                                            error: nil) {
                    if resource as? Int == 1 {
                        continue
                    }
                }
                URLs.append(fileURL)
            }
            return true
        }
    }
    return false
}

