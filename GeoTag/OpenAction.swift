//
//  OpenAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import UniformTypeIdentifiers
import SwiftUI

// Extension to our Application State that handles file open and dropping
// URLs onto the app's table of images to edit.

extension AppViewModel {

    /// Display the File -> Open... panel for image and gpx files.  Folders may also be selected.

    func showOpenPanel() {

        // allow image and gpx types
        var types = [UTType.image]
        if let type = UTType(filenameExtension: "gpx") {
            types.append(type)
        }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = types
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true

        // process any URLs selected to open on a detached task
        if panel.runModal() == NSApplication.ModalResponse.OK {
            prepareForEdit(inputURLs: panel.urls)
        }
    }

    /// process URLs opened or dragged to the app.  In the case of a drag a URL may
    /// be of any type.  The path of non-image files will be listed in the app's table but will
    /// not be flagged as a valid image.

    func prepareForEdit(inputURLs: [URL]) {
        var gpxFound = false
        @AppStorage(AppSettings.disablePairedJpegsKey) var disablePairedJpegs = false

        ContentViewModel.shared.showingProgressView = true

        // dragged urls are duplicated for some reason. Make an array
        // of unique URLs including those in any containing folder.

        let imageURLs = inputURLs.uniqued()
            .flatMap { url in
                isFolder(url: url) ? urlsIn(folder: url) : [url]
            }

        // check for duplicates of images already open for procesing

        let processedURLs = Set(images.map {$0.fileURL })
        let duplicateURLs = imageURLs.filter { processedURLs.contains($0) }
        if !duplicateURLs.isEmpty {
            ContentViewModel.shared.addSheet(type: .duplicateImageSheet)
        }

        // check the given URLs.  They may point to GPX files or image files.
        // Images are added to the table as soon as they are processed.
        // Track are not added until all urls are processed.

        let updateGroup = DispatchGroup()
        for url in imageURLs where !duplicateURLs.contains(url) {
            let gpxFile = url.pathExtension.lowercased() == "gpx"
            if gpxFile {
                gpxFound = true
            }
            updateGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                if gpxFile {
                    self.parseGpxFile(url)
                } else {
                    do {
                        let image = try ImageModel(imageURL: url)
                        DispatchQueue.main.async {
                            self.images.append(image)
                        }
                    } catch let error as NSError {
                        DispatchQueue.main.async {
                            ContentViewModel.shared.addSheet(type: .unexpectedErrorSheet,
                                                             error: error,
                                                             message: "Failed to open file \(url.path)")
                        }
                    }
                }
                DispatchQueue.main.async {
                    updateGroup.leave()
                }
            }
        }

        // once every image has been processed link paired images, sort the
        // images into the desired sequence, schedule a sheet if gpx files
        // were processed and turn off the progress indicator

        updateGroup.notify(queue: DispatchQueue.main) {
            self.linkPairedImages()
            self.images.sort(using: self.sortOrder)
            if gpxFound {
                ContentViewModel.shared.addSheet(type: .gpxFileNameSheet)
            }
            ContentViewModel.shared.showingProgressView = false
        }
    }

    /// Check if a given file URL refers to a folder

    private func isFolder(url: URL) -> Bool {
        let resources = try? url.resourceValues(forKeys: [.isDirectoryKey])
        return resources?.isDirectory ?? false
    }

    /// iterate over a folder looking for files.
    /// Returns an array of contained the urls

    private func urlsIn(folder url: URL) -> [URL] {
        var foundURLs = [URL]()
        let fileManager = FileManager.default
        guard let urlEnumerator =
                fileManager.enumerator(at: url,
                                       includingPropertiesForKeys: [.isDirectoryKey],
                                       options: [.skipsHiddenFiles],
                                       errorHandler: nil) else { return []}
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            if !isFolder(url: fileUrl) {
                foundURLs.append(fileUrl)
            }
        }
        return foundURLs
    }

    // process GPX files (called in an async thread).

    func parseGpxFile(_ url: URL) {
        do {
            let gpx = try Gpx(contentsOf: url)
            try gpx.parse()
            DispatchQueue.main.async {
                self.gpxTracks.append(gpx)
                self.gpxGoodFileNames.append(url.path)
            }
        } catch {
            DispatchQueue.main.async {
                self.gpxBadFileNames.append(url.path)
            }
        }
    }

    // either link raw/jpeg images to each other by storing the URL of the
    // other half of the pair in the image or disable the jpeg version if
    // that option is selected

    private func linkPairedImages() {
        @AppStorage(AppSettings.disablePairedJpegsKey) var disablePairedJpegs = false

        let imageURLs = images.map { $0.fileURL }

        for url in imageURLs {
            // only look at jpeg files
            let pathExtension = url.pathExtension.lowercased()
            guard pathExtension == "jpg" || pathExtension == "jpeg" else { continue }

            // extract the base URL for comparison
            let baseURL = url.deletingPathExtension()

            // look for non-xmp files that match baseURL
            for pairedURL in imageURLs where pairedURL != url
                && pairedURL.pathExtension.lowercased() != xmpExtension
                && pairedURL.deletingPathExtension() == baseURL {
                // url and otherURL are part of an image pair.
                self[url].pairedID = pairedURL
                self[pairedURL].pairedID = url
                // disable the jpeg version if requested
                if disablePairedJpegs {
                    self[url].isValid = false
                }
                break
            }
        }
    }
}

// make sure the entries in an array are unique
// Code from: https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array-in-swift
// which is much cleaner then any home grown solution I was thinking about.

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
