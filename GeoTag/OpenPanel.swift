//
//  OpenPanel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import UniformTypeIdentifiers
import AppKit

    /// Display the File -> Open... panel for image and gpx files.  Folders may also be selected.
    ///
    /// - Parameter appState: program state containing the array of images to process
func showOpenPanel(_ appState: AppState) {

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
        var urls = [URL]()
        for url in panel.urls {
            if !findUrlsInFolder(appState, url: url, toUrls: &urls) {
                if !isGpxFile(appState, url) {
                    urls.append(url)
                }
            }
        }
//        let dups = tableViewController.addImages(urls: urls)
//        if dups {
//            let alert = NSAlert()
//            alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
//            alert.messageText = NSLocalizedString("WARN_TITLE", comment: "Files not opened")
//            alert.informativeText = NSLocalizedString("WARN_DESC", comment: "Files not opened")
//            alert.runModal()
//        }
    }
}

/// If a given URL is a folder iterate over the folder looking for files.
/// - Parameters:
///   - appState: program state variables
///   - url: The URL to check.  It will be
///   - urls: an array of URLs to which non folder URLs will be added
/// - Returns: true when url referenced a folder, otherwise fasle
private func findUrlsInFolder(
    _ appState: AppState,
    url: URL,
    toUrls urls: inout [URL]
) -> Bool {
    let fileManager = FileManager.default
    var dir = ObjCBool(false)
    if fileManager.fileExists(atPath: url.path, isDirectory: &dir) &&
        dir.boolValue {
        guard let urlEnumerator =
            fileManager.enumerator(at: url,
                                   includingPropertiesForKeys: [.isDirectoryKey],
                                   options: [.skipsHiddenFiles],
                                   errorHandler: nil) else { return false }
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            guard let resources =
                try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]),
                let directory = resources.isDirectory
                else { continue }
            if !directory {
                if !isGpxFile(appState, fileUrl) {
                    urls.append(fileUrl)
                }
            }
        }
        return true
    }
    return false
}


/// check if the given url is a valid gpx file.  A valid gpx file ends in .gpx and can be parsed
/// by the GPX parser without error.
///
/// - Parameters:
///   - appState: program state variables
///   - url: URL of file to check
/// - Returns: true if file is a gpx file, otherwise false
private func isGpxFile(
    _ appState: AppState,
    _ url: URL
) -> Bool {
    if url.pathExtension.lowercased() == "gpx" {
        if let gpx = Gpx(contentsOf: url) {
            if gpx.parse() {
                // add the track to the map
                appState.gpxTracks.append(gpx)
                // put up an alert
                let alert = NSAlert()
                alert.alertStyle = NSAlert.Style.informational
                alert.addButton(withTitle: "Close")
                alert.messageText = "GPX file loaded"
                alert.informativeText = url.path
                alert.informativeText += "GPX file loaded"
                alert.runModal() //  should be a sheet
            } else {
                // put up an alert
                let alert = NSAlert()
                alert.alertStyle = NSAlert.Style.informational
                alert.addButton(withTitle: "Close")
                alert.messageText = "Bad GPX file"
                alert.informativeText = url.path
                alert.informativeText += "Bad GPX file"
                alert.runModal() // should be a sheet
            }
//                progressIndicator.stopAnimation(self)
        }
        return true
    }
    return false
}
