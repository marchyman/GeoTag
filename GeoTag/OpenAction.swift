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

extension ViewModel {

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
        @AppStorage(AppSettings.disablePairedJpegs) var disablePairedJpegs = false

        showingProgressView = true

        // dragged urls are duplicated for some reason. Make an array
        // of unique URLs including those in any containing folder

        let imageURLs = inputURLs.uniqued().flatMap { url in
            isFolder(url: url) ? urlsIn(folder: url) : [url]
        }

        // check the given URLs.  They may point to GPX files or image files.
        // Images are added to the table as soon as they are processed.
        // Track are not added until all urls are processed.

        Task {
            let helper = URLToImageHelper(knownImages: images)
            await withTaskGroup(of: ImageModel?.self) { group in
                for url in imageURLs {
                    group.addTask {
                        let image = await helper.urlToImage(url: url)
                        return image
                    }
                }
                for await image in group {
                    if let image {
                        images.append(image)
                    }
                }
            }

            // copy track info from helper to ViewModel
            for gpxTrack in await helper.gpxTracks {
                updateTracks(gpx: gpxTrack)
                gpxTracks.append(gpxTrack)
            }
            gpxGoodFileNames = await helper.gpxGoodFileNames
            gpxBadFileNames = await helper.gpxBadFileNames

            // copy sheet info from helper to ViewModel
            if await !helper.sheetStack.isEmpty {
                sheetStack.append(contentsOf: await helper.sheetStack)
                let sheetInfo = sheetStack.removeFirst()
                sheetMessage = sheetInfo.sheetMessage
                sheetError = sheetInfo.sheetError
                sheetType = sheetInfo.sheetType
            }

            // disable paired jpegs if desired
            if disablePairedJpegs {
                disableJpegs()
            }
            showingProgressView = false
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

    // if a jpg/jpeg image is part of a raw/jpeg pair disable the jpeg by
    // turning off its isValid flag.

    func disableJpegs() {
        let imageURLs = images.map{ $0.fileURL }

        for url in imageURLs {
            let pathExtension = url.pathExtension.lowercased()
            guard pathExtension == "jpg" || pathExtension == "jpeg" else { continue }
            let pathWithoutExtension = url.deletingPathExtension().path
            for urlToCheck in imageURLs {
                let checkPathExtension = urlToCheck.pathExtension.lowercased()
                if checkPathExtension != "jpg" && checkPathExtension != "jpeg" {
                    if pathWithoutExtension == urlToCheck.deletingPathExtension().path {
                        self[url].isValid = false
                    }
                }
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
