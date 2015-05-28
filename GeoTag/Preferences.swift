//
//  Preferences.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright (c) 2015 Marco S Hyman. All rights reserved.
//

import Cocoa

final class Preferences : NSWindowController {
    static let nibName = "Preferences"
    static let saveDirectoryKey = "SaveDirectoryKey"
    static var checkDirectory = true

    // user defaults key for optional save directory

    class func saveDirectory() -> NSURL? {
        var saveDirectory: NSURL? = nil

        if checkDirectory {
            let defaults = NSUserDefaults.standardUserDefaults()
            saveDirectory = defaults.URLForKey(Preferences.saveDirectoryKey)
            if saveDirectory != nil {
                let fileManager = NSFileManager.defaultManager()
                if !fileManager.fileExistsAtPath(saveDirectory!.path!) {
                    unexpectedError(nil, "The specified Optional Save Folder\n\n\t\(saveDirectory!.path!)\n\nis missing. Original image files will not be copied to that location.")
                    saveDirectory = nil
                    checkDirectory = false
                }
            }
        }
        return saveDirectory
    }

    @IBOutlet var saveDirPath: NSPathControl!

    @IBAction func pickSaveFolder(sender: AnyObject) {
        println("Pick Save Folder")
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            saveDirPath.URL = panel.URLs[0] as? NSURL
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setURL(saveDirPath.URL!,
                            forKey: Preferences.saveDirectoryKey)
        }
    }

	@IBAction func clearSaveDir(AnyObject!) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(Preferences.saveDirectoryKey)
        saveDirPath.URL = nil
    }

	override var windowNibName: String {
		return Preferences.nibName
	}

    override func windowDidLoad() {
        if let saveDirURL = Preferences.saveDirectory() {
            saveDirPath.URL = saveDirURL
        }
    }

    // window delegate function... orderOut instead of close
    func windowShouldClose(sender: AnyObject!) -> Bool {
        window!.orderOut(sender)
        return false
    }
}