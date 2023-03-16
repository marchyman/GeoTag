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

final class XmpPresenter: NSObject {
    let imageURL: URL   // url of image file
    let sidecarURL: URL // url of sidecar file

    init(imageURL: URL, sidecarURL: URL) {
        self.imageURL = imageURL
        self.sidecarURL = sidecarURL
    }
}

// MARK: - NSFilePresenter

extension XmpPresenter: NSFilePresenter {
    var presentedItemURL: URL? {
        return sidecarURL
    }

    var primaryPresentedItemURL: URL? {
        return imageURL
    }

    var presentedItemOperationQueue: OperationQueue {
        if let queue = OperationQueue.current {
            return queue
        }
        return OperationQueue.main
    }
}

extension XmpPresenter: Sendable {}
