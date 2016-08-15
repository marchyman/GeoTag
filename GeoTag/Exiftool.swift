//
//  Exiftool.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/15/16.
//  Copyright © 2016 Marco S Hyman. All rights reserved.
//

import Foundation
import AppKit

/// manage GeoTag's use of exiftool
struct Exiftool {
    let exiftoolBookmarkKey = "exiftoolBookmarkKey"

    var bookmark: Data?
    var url: URL?

    /// Find the security scoped bookmark for exiftool.
    /// - Returns: nil if a bookmark for exiftool could not be found or
    ///             created
    ///
    /// If a bookmark was not found try to create one from the users
    /// open panel choice.
    init?() {
        let defaults = UserDefaults.standard
        bookmark = defaults.data(forKey: exiftoolBookmarkKey)

        // If a bookmark was found verify it is still valid

        if let bookmark = bookmark {
            var staleBookmark = true
            do {
                url = try URL(resolvingBookmarkData: bookmark,
                              options: [.withoutUI, .withSecurityScope],
                              bookmarkDataIsStale: &staleBookmark)
            } catch let error as NSError {
                print("Bookmark Access Fails: \(error.description)")
            }
            if url == nil || staleBookmark {
                print("stale bookmark")
                self.bookmark = nil
            }
        }

        if bookmark == nil {
            print("No security bookmark found")

            // tell the user they must select the path to exiftool

            let alert = NSAlert()
            alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
            alert.addButton(withTitle: NSLocalizedString("SET_EXIFTOOL_PATH",
                            comment: "Choose exiftool path"))
            alert.messageText = NSLocalizedString("NO_EXIFTOOL_TITLE",
                                                  comment: "can't find exiftool")
            alert.informativeText = NSLocalizedString("NO_EXIFTOOL_DESC",
                                                      comment: "can't find exiftool")
            switch (alert.runModal()) {
            case NSAlertSecondButtonReturn:
                break
            default:
                return nil
            }

            // Look for the executable in the usual places to make it
            // easier for the user. The found directory is used when
            // the open panel is displayed

            let fileManager = FileManager.default
            let paths = ["/usr/bin", "/usr/local/bin", "/opt/bin"]
            var exiftoolPath: String? = nil
            for path in paths {
                let fullPath = path + "/exiftool"
                if fileManager.fileExists(atPath: fullPath) {
                    exiftoolPath = fullPath
                    break
                }
            }

            // show an open panel to allow the user to select the
            // exiftool executable.

            let openPanel = NSOpenPanel()
            if let filePath = exiftoolPath {
                openPanel.directoryURL = URL(fileURLWithPath: filePath)
            }
            openPanel.canChooseFiles = true
            openPanel.canCreateDirectories = false
            openPanel.canChooseDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.showsHiddenFiles = true
            switch (openPanel.runModal()) {
            case NSFileHandlingPanelOKButton:
                url = openPanel.url
            default:
                return nil
            }

            // create a security bookmark for the item and save it in
            // program defaults

            if let url = url {
                do {
                    try bookmark = url.bookmarkData(options: .withSecurityScope)
                } catch let error as NSError {
                    unexpected(error: error,
                               "Cannot create security bookmark for exiftool\n\nReason: ")
                }
                defaults.set(bookmark, forKey: exiftoolBookmarkKey)
            } else {
                return nil
            }
        }
    }

    func updateLocation(from imageData: ImageData, overwriteOriginal: Bool) {
        guard let url = url else { return }

        // latitude exiftool args
        var latArg = "-GPSLatitude="
        var latRefArg = "-GPSLatitudeRef="
        if var lat = imageData.latitude {
            if lat < 0 {
                latRefArg += "S"
                lat = -lat
            } else {
                latRefArg += "N"
            }
            latArg += "\(lat)"
        }

        // longitude exiftool args
        var lonArg = "-GPSLongitude="
        var lonRefArg = "-GPSLongitudeRef="
        if var lon = imageData.longitude {
            if lon < 0 {
                lonRefArg += "W"
                lon = -lon
            } else {
                lonRefArg += "E"
            }
            lonArg += "\(lon)"
        }

        let exiftool = Process()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = FileHandle.nullDevice
        exiftool.launchPath = url.path
        exiftool.arguments = ["-q", "-m", "-DateTimeOriginal>FileModifyDate",
            latArg, latRefArg, lonArg, lonRefArg, imageData.path]

        // add -overwrite_original option to the exiftool args if we were
        // able to create a backup.
        if overwriteOriginal {
            exiftool.arguments?.insert("-overwrite_original", at: 2)
        }
        let _ = url.startAccessingSecurityScopedResource()
        exiftool.launch()
        exiftool.waitUntilExit()
        url.stopAccessingSecurityScopedResource()
    }
}
