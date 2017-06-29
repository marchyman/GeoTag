//
//  Preferences.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright (c) 2015 Marco S Hyman, CC-BY-NC
//

import Foundation
import AppKit

final class Preferences : NSWindowController {
    // class constants
    static let nibName = "Preferences"
    static let saveBookmarkKey = "SaveBookmarkKey"
    static var checkDirectory = true
    private static var url: URL? = nil

    /// fetch the URL of the optional save folder
    /// - Returns: the URL associated with the save directory security bookmark
    ///   if one has been specified
    ///
    /// If a save directory/folder has been specified but does not exist an
    /// alert is shown.
    class func saveFolder() -> URL? {
        if checkDirectory {
            checkDirectory = false
            url = nil
            let defaults = UserDefaults.standard
            if let bookmark = defaults.data(forKey: saveBookmarkKey) {
                var staleBookmark = true
                do {
                    url = try URL(resolvingBookmarkData: bookmark,
                                  options: [.withoutUI, .withSecurityScope],
                                  bookmarkDataIsStale: &staleBookmark)
                } catch let error as NSError {
                    unexpected(error: error, "Problem locating optional save folder")
                }
                if staleBookmark {
                    unexpected(error: nil, "The specified Optional Save Folder\n\n\t\(url?.path ?? "[unknown]"))\n\nis missing.  Please select a new folder.")
                    url = nil
                }

            }
        }
        return url
    }

    @IBOutlet var saveFolderPath: NSPathControl!

    /// select a save folder
    /// - Parameter AnyObject: unused
    ///
    /// Allow the user to pick or create a folder where the original
    /// copies of updated images will be saved (in addition to moving
    /// the file to the system trash.
    
    @IBAction func pickSaveFolder(_: AnyObject) {
        var bookmark: Data? = nil
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            if let url = panel.url {
                do {
                    try bookmark = url.bookmarkData(options: .withSecurityScope)
                    saveFolderPath.url = url
                } catch let error as NSError {
                    unexpected(error: error,
                               "Cannot create security bookmark for save folder\n\nReason: ")
                }
                let defaults = UserDefaults.standard
                defaults.set(bookmark, forKey: Preferences.saveBookmarkKey)
                Preferences.checkDirectory = true
            } else {
                unexpected(error: nil,
                               "Cannot create save folder\n\nReason: ")
            }
        }
    }

    /// remove the optional save folder from user preferences
    /// - Parameter AnyObject: unused

	@IBAction func clearSaveFolder(_: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Preferences.saveBookmarkKey)
        saveFolderPath.url = nil
        Preferences.checkDirectory = true
    }

    /// return the NIB name for this window

	override var windowNibName: String {
		return Preferences.nibName
	}

    /// initialize the saveFolderPath field from user preferences

    override func windowDidLoad() {
        saveFolderPath.url = Preferences.saveFolder()
    }

    // window delegate function... orderOut instead of close

    func windowShouldClose(sender: AnyObject!) -> Bool {
        if let window = window {
            window.orderOut(sender)
        }
        return false
    }
}
