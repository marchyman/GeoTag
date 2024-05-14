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

final class XmpPresenter: NSObject, NSFilePresenter {
    let primaryPresentedItemURL: URL?
    let presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue {
        if let queue = OperationQueue.current {
            return queue
        }
        return OperationQueue.main
    }

    init(for imageURL: URL) {
        primaryPresentedItemURL = imageURL
        presentedItemURL = imageURL
            .deletingPathExtension()
            .appendingPathExtension(xmpExtension)
    }
}

extension XmpPresenter {

    // return the contents of the presentedItemURL

    func readData() -> Data? {
        var data: Data?
        var error: NSError?
        let coordinator = NSFileCoordinator.init(filePresenter: self)
        coordinator.coordinate(readingItemAt: presentedItemURL!,
                               options: [],
                               error: &error) { url in
            data = try? Data(contentsOf: url)
        }
        return data
    }
}
