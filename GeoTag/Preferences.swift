//
//  Preferences.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright (c) 2015 Marco S Hyman. All rights reserved.
//

import Cocoa

let preferencesNibName = "Preferences"
let saveDirectoryKey = "SaveDirectoryKey"

class Preferences : NSWindowController {
    // user defaults key for optional save directory

    class func saveDirectory() -> NSURL? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.URLForKey(saveDirectoryKey)
    }

    @IBOutlet var saveDirPath: NSPathControl!

    @IBAction func pickSaveFolder(sender: AnyObject) {
        println("Pick Save Folder")
        var panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            saveDirPath.URL = panel.URLs[0] as? NSURL
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setURL(saveDirPath.URL!, forKey: saveDirectoryKey)
        }
    }

	@IBAction func clearSaveDir(AnyObject!) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(saveDirectoryKey)
        saveDirPath.URL = nil
    }

	override var windowNibName: String {
		return preferencesNibName
	}

    // window delegate function... orderOut instead of close
    func windowShouldClose(sender: AnyObject!) -> Bool {
        window!.orderOut(sender)
        return false
    }
}