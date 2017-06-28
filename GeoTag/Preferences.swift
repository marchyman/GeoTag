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
    // class constants and a flag
    static let nibName = "Preferences"
    static let saveFolderKey = "saveDirectoryKey"
    static var checkDirectory = true

    /// fetch the URL of the optional extra save folder/directory
    /// - Returns: the URL of the save directory if one has been specified
    ///
    /// If a save directory/folder has been specified but does not exist an
    /// alert is shown once per execution to inform the user.

    class func saveFolder() -> URL? {
        var saveFolder: URL? = nil

        if checkDirectory {
            let defaults = UserDefaults.standard
            saveFolder = defaults.url(forKey: Preferences.saveFolderKey)
            if let path = saveFolder?.path {
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: path) {
                    unexpected(error: nil, "The specified Optional Save Folder\n\n\t\(path)\n\nis missing. Original image files will not be copied to that location.")
                    saveFolder = nil
                    checkDirectory = false
                }
            }
        }
        return saveFolder
    }

    @IBOutlet var saveFolderPath: NSPathControl!

    /// select a save folder
    /// - Parameter AnyObject: unused
    ///
    /// Allow the user to pick or create a folder where the original
    /// copies of updated images will be saved (in addition to moving
    /// the file to the system trash.
    
    @IBAction func pickSaveFolder(_: AnyObject) {
        print("Pick Save Folder")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            saveFolderPath.url = panel.urls[0]
            guard let url = saveFolderPath.url else { return }
            let defaults = UserDefaults.standard
            defaults.set(url, forKey: Preferences.saveFolderKey)
        }
    }

    /// remove the optional save folder from user preferences
    /// - Parameter AnyObject: unused

	@IBAction func clearSaveFolder(_: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Preferences.saveFolderKey)
        saveFolderPath.url = nil
    }

    /// return the NIB name for this window

	override var windowNibName: String {
		return Preferences.nibName
	}

    /// initialize the saveFolderPath field from user preferences

    override func windowDidLoad() {
        let defaults = UserDefaults.standard
        saveFolderPath.url = defaults.url(forKey: Preferences.saveFolderKey)
    }

    // window delegate function... orderOut instead of close

    func windowShouldClose(sender: AnyObject!) -> Bool {
        if let window = window {
            window.orderOut(sender)
        }
        return false
    }
}
