//
//  OpenAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import UniformTypeIdentifiers
import AppKit

// Extension to our Application State that handles file open and dropping
// URLs onto the app's table of images to edit.

extension AppState {

    /// Display the File -> Open... panel for image and gpx files.  Folders may also be selected.
    ///
    /// - Parameter appState: program state containing the array of images to process
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
    ///
    func prepareForEdit(inputURLs: [URL]) {
        showingProgressView = true

        // dragged urls are duplicated for some reason. Make an array
        // of unique URLs including those in any containing folder

        let imageURLs = inputURLs.uniqued().flatMap { url in
            isFolder(url: url) ? urlsIn(folder: url) : [url]
        }

        // check the given URLs.  They may point to GPX files or image
        // files.  Work for each image is done in an image group.

        var helper = URLToImageHelper(knownImages: images)
        let group = DispatchGroup()
        for url in imageURLs {
            group.enter()
            helper.urlToImage(url: url)
            group.leave()
        }

        // Update the app state once all the images have been processed.
        group.notify(queue: .global(qos: .userInitiated)) {
            DispatchQueue.main.async {
                self.images.append(contentsOf: helper.images)
                for gpxTrack in helper.gpxTracks {
                    self.updateTracks(gpx: gpxTrack)
                    self.gpxTracks.append(gpxTrack)
                }
                self.gpxGoodFileNames = helper.gpxGoodFileNames
                self.gpxBadFileNames = helper.gpxBadFileNames
                self.sheetType = helper.sheetType
                self.sheetError = helper.sheetError
                self.sheetMessage = helper.sheetMessage
                self.showingProgressView = false
            }
        }
    }

    /// Check if a given file URL refers to a folder
    ///
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
