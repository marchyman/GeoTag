//
//  XmpFile.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/13/19.
//

import Foundation

/// file extension used for sidecar files

let xmpExtension = "xmp"

/// Class used to access xmp sidecar files as related files to the image
/// file being updated in a sandboxed environment.

class XmpFile: NSObject {
    var url: URL        // url of image file

    init(url: URL) {
        self.url = url
    }
}

// MARK: - NSFilePresenter

extension XmpFile: NSFilePresenter {
    var presentedItemURL: URL? {
        var xmp = url.deletingPathExtension()
        xmp.appendPathExtension(xmpExtension)
        return xmp
    }
    
    var primaryPresentedItemURL: URL? {
        return url
    }
    
    var presentedItemOperationQueue: OperationQueue {
        if let queue = OperationQueue.current {
            return queue
        }
        return OperationQueue.main
    }
}
