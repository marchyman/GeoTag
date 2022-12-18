//
//  OpenPanel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import UniformTypeIdentifiers
import AppKit

// Extension to our Application State that handles file open

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

        // process any URLs selected to open.
        if panel.runModal() == NSApplication.ModalResponse.OK {
            gpxGoodFileNames.removeAll()
            gpxBadFileNames.removeAll()
            var urls = [URL]()
            for url in panel.urls {
                if isFolder(url: url) {
                    findUrlsInFolder(url: url, toUrls: &urls)
                } else {
                    if url.pathExtension.lowercased() == "gpx" {
                        parseGpxFile(url)
                    } else {
                        urls.append(url)
                    }
                }
            }

            // add the selected images to the array of images to be edited

            for url in urls {
                if imageURLs.contains(url) {
                    sheetType = .duplicateImageSheet
                } else {
                    imageURLs.insert(url)
                    do {
                        let imageData = try ImageModel(imageURL: url)
                        images.append(imageData)
                    } catch let error as NSError {
                        print("Error: \(error)")
                        //                        DispatchQueue.main.async {
                        //                            let desc = NSLocalizedString("WARN_DESC_2",
                        //                                                         comment: "cant process file error")
                        //                            + "\(url.path)\n\nReason: "
                        //                            unexpected(error: error, desc)
                        //                        }
                        // alert here
                    }
                }
            }
        }
    }

    /// Check if a given file URL refers to a folder
    ///
    private func isFolder(url: URL) -> Bool {
        let fileManager = FileManager.default
        var dir = ObjCBool(false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &dir) &&
        dir.boolValue
    }

    /// iterate over a folder looking for files.
    /// - Parameters:
    ///   - appState: program state variables
    ///   - url: The URL to check.  It will be
    ///   - urls: an array of URLs to which non folder URLs will be added
    /// - Returns: true when url referenced a folder, otherwise fasle
    private func findUrlsInFolder(url: URL, toUrls urls: inout [URL]) {
        let fileManager = FileManager.default
        guard let urlEnumerator =
                fileManager.enumerator(at: url,
                                       includingPropertiesForKeys: [.isDirectoryKey],
                                       options: [.skipsHiddenFiles],
                                       errorHandler: nil) else { return }
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            guard let resources =
                    try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]),
                  let directory = resources.isDirectory
            else { continue }
            if !directory {
                if fileUrl.pathExtension.lowercased() == "gpx" {
                    parseGpxFile(fileUrl)
                } else {
                    urls.append(fileUrl)
                }
            }
        }
    }

    /// Parse the given url is a valid gpx file.  A valid gpx file ends in .gpx and can be parsed
    /// by the GPX parser without error.
    ///
    /// - Parameters:
    ///   - appState: program state variables
    ///   - url: URL of file to parse
    /// - Returns: true if file is a gpx file, otherwise false
    private func parseGpxFile(_ url: URL) {
        if let gpx = Gpx(contentsOf: url) {
            sheetType = .gpxFileNameSheet
            if gpx.parse() {
                // add the track to the map
                gpxTracks.append(gpx)
                gpxGoodFileNames.append(url.path)
            } else {
                gpxBadFileNames.append(url.path)
            }
        }
    }

}
