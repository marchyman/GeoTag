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

extension AppState {

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

        // process any URLs selected to open in the background
        if panel.runModal() == NSApplication.ModalResponse.OK {
            Task.detached {
                await self.prepareForEdit(inputURLs: panel.urls)
            }
        }
    }

    /// process URLs opened or dragged to the app.  In the case of a drag a URL may
    /// be of any type.  The path of non-image files will be listed in the app's table but will
    /// not be flagged as a valid image.

    func prepareForEdit(inputURLs: [URL]) async {

        // show the progress view

        applicationBusy = true

        // expand folder URLs and remove any duplicates.

        let imageURLs = inputURLs
            .flatMap { url in
                isFolder(url: url) ? urlsIn(folder: url) : [url]
            }
            .uniqued()

        // check for duplicates of URLs already open for processing
        // if any are found notify the user

        let processedURLs = Set(tvm.images.map {$0.fileURL })
        let duplicateURLs = imageURLs.filter { processedURLs.contains($0) }
        if !duplicateURLs.isEmpty {
            addSheet(type: .duplicateImageSheet)
        }

        await images(for: imageURLs)
        linkPairedImages()
        tvm.images.sort(using: tvm.sortOrder)

        // now process any gpx tracks

        let gpxURLs = imageURLs.filter { $0.pathExtension.lowercased() == "gpx" }
        if !gpxURLs.isEmpty {

            // if the appViewModel update isn't done on the main queue the
            // Discard tracks menu item doesn't see the approriate state.

            let updatedTracks = await tracks(for: gpxURLs)
            DispatchQueue.main.async {
                for (path, track) in updatedTracks {
                    if let track {
                        self.updateTracks(gpx: track)
                        self.gpxGoodFileNames.append(path)
                        self.gpxTracks.append(track)
                    } else {
                        self.gpxBadFileNames.append(path)
                    }
                }
                self.addSheet(type: .gpxFileNameSheet)
            }
        }

        applicationBusy = false
    }

    // process all urls in a task group, one task per url.  Skip
    // gpx urls for now
    private func images(for imageURLs: [URL]) async {
        await withTaskGroup(of: ImageModel?.self) { group in
            var openedImages: [ImageModel] = []

            for url in imageURLs {
                guard url.pathExtension.lowercased() != "gpx" else { continue }
                group.addTask {
                    do {
                        return try ImageModel(imageURL: url)
                    } catch let error as NSError {
                        self.addSheet(type: .unexpectedErrorSheet,
                                      error: error,
                                      message: "Failed to open file \(url.path)")
                        return nil
                    }
                }
            }
            for await image in group.compactMap({ $0 }) {
                openedImages.append(image)
            }
            tvm.images.append(contentsOf: openedImages)
        }
    }

    // process gpx track files
    private func tracks(for gpxURLs: [URL]) async -> [(String, Gpx?)] {
        var tracks: [(String, Gpx?)] = []

        await withTaskGroup(of: (String, Gpx?).self ) { group in
            for url in gpxURLs {
                group.addTask {
                    do {
                        let gpx = try Gpx(contentsOf: url)
                        try gpx.parse()
                        return (url.path, gpx)
                    } catch {
                        return (url.path, nil)
                    }
                }
            }
            for await (path, gpx) in group {
                tracks.append((path, gpx))
            }
        }
        return tracks
    }

    // Check if a given file URL refers to a folder
    private func isFolder(url: URL) -> Bool {
        let resources = try? url.resourceValues(forKeys: [.isDirectoryKey])
        return resources?.isDirectory ?? false
    }

    // iterate over a folder looking for files.
    // Returns an array of contained the urls
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

    // either link raw/jpeg images to each other by storing the URL of the
    // other half of the pair in the image or disable the jpeg version if
    // that option is selected

    private func linkPairedImages() {
        @AppStorage(AppSettings.disablePairedJpegsKey) var disablePairedJpegs = false

        let imageURLs = tvm.images.map { $0.fileURL }

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
                tvm[url].pairedID = pairedURL
                tvm[pairedURL].pairedID = url
                // disable the jpeg version if requested
                if disablePairedJpegs {
                    tvm[url].isValid = false
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
