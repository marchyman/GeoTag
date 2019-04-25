//
//  XmpFile.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/13/19.
//  Copyright © 2019 Marco S Hyman. All rights reserved.
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

/// Class used to access xmp sidecar files as related files to the image
/// file being updated in a sandboxed environment.

class XmpFile: NSObject {
    var url: URL        // url of image file
    let ext = "xmp"     // extension used with sidecar files

    init(url: URL) {
        self.url = url
    }
}

// MARK: - NSFilePresenter
extension XmpFile: NSFilePresenter {
    var presentedItemURL: URL? {
        var xmp = url.deletingPathExtension()
        xmp.appendPathExtension(ext)
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
