//
//  OpenPanel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import UniformTypeIdentifiers
import AppKit

func showOpenPanel(_ appState: AppState) {
    var types = [UTType.image]
    if let type = UTType(filenameExtension: "gpx") {
        types.append(type)
    }
    let panel = NSOpenPanel()
    panel.allowedContentTypes = types
    panel.allowsMultipleSelection = true
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    if panel.runModal() == NSApplication.ModalResponse.OK {
//        var urls = [URL]()
        for url in panel.urls {
            print("URL: \(url)")
//            if !addUrlsInFolder(url: url, toUrls: &urls) {
//                if !isGpxFile(url) {
//                    urls.append(url)
//                }
//            }
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
