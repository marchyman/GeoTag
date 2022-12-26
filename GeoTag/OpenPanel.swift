//
//  OpenPanel.swift
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
        // dragged urls are duplicated for some reason. Make an array
        // if unique URLs.
        let urls = inputURLs.uniqued()
        var imageURLs = [URL]()
        gpxGoodFileNames.removeAll()
        gpxBadFileNames.removeAll()

        // expand the list of inputURLs by recursing into folders
        imageURLs = urls.flatMap { url in
            isFolder(url: url) ? urlsIn(folder: url) : [url]
        }

        // check the given URLs.  Iterate into folders and special case
        // gpx files.  Add what may be image URLs to the imageURLs array.

        // Process the URLs
        for url in imageURLs {
            if url.pathExtension.lowercased() == "gpx" {
                parseGpxFile(url)
            } else if processedURLs.contains(url) {
                sheetType = .duplicateImageSheet
            } else {
                processedURLs.insert(url)
                do {
                    let imageData = try ImageModel(imageURL: url)
                    images.append(imageData)
                } catch let error as NSError {
                    sheetMessage = "Failed to open file \(url.path)"
                    sheetError = error
                    sheetType = .unexpectedErrorSheet
                }
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

    /// Parse the given url to see if it is a valid gpx file.  A valid gpx file ends in .gpx and can be parsed
    /// by the GPX parser without error.
    ///
    /// - Parameters:
    ///   - url: URL of file to parse
    /// - Returns: true if file is a gpx file, otherwise false
    private func parseGpxFile(_ url: URL) {
        do {
            let gpx = try Gpx(contentsOf: url)
            try gpx.parse()
            gpxTracks.append(gpx)
            gpxGoodFileNames.append(url.path)
            sheetType = .gpxFileNameSheet
        } catch Gpx.GpxParseError.gpxParsingError {
            gpxBadFileNames.append(url.path)
            if sheetType == .none {
                sheetMessage = "\(url.path) is not a valid GPX file"
                sheetType = .unexpectedErrorSheet
            }
        } catch {
            gpxBadFileNames.append(url.path)
            sheetType = .gpxFileNameSheet
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
