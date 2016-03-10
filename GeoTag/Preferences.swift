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

    class func saveFolder() -> NSURL? {
        var saveFolder: NSURL? = nil

        if checkDirectory {
            let defaults = NSUserDefaults.standardUserDefaults()
            saveFolder = defaults.URLForKey(Preferences.saveFolderKey)
            if let path = saveFolder?.path {
                let fileManager = NSFileManager.defaultManager()
                if !fileManager.fileExistsAtPath(path) {
                    unexpectedError(nil, "The specified Optional Save Folder\n\n\t\(path)\n\nis missing. Original image files will not be copied to that location.")
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
            saveFolderPath.URL = panel.URLs[0]
            guard let url = saveFolderPath.URL else { return }
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setURL(url, forKey: Preferences.saveFolderKey)
        }
    }

    /// remove the optional save folder from user preferences
    /// - Parameter AnyObject: unused

	@IBAction func clearSaveFolder(_: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(Preferences.saveFolderKey)
        saveFolderPath.URL = nil
    }

    /// return the NIB name for this window

	override var windowNibName: String {
		return Preferences.nibName
	}

    /// initialize the saveFolderPath field from user preferences

    override func windowDidLoad() {
        let defaults = NSUserDefaults.standardUserDefaults()
        saveFolderPath.URL = defaults.URLForKey(Preferences.saveFolderKey)
    }

    // window delegate function... orderOut instead of close

    func windowShouldClose(sender: AnyObject!) -> Bool {
        window!.orderOut(sender)
        return false
    }
}