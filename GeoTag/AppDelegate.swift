//
//  AppDelegate.swift
//  GeoTag (3rd version)
//
//  Created by Marco S Hyman on 6/11/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    // class variable holds path to exiftool
    static var exiftoolPath: String!
    lazy var preferences = Preferences(windowNibName: Preferences.nibName)

    @IBOutlet var window: NSWindow!
    @IBOutlet var tableViewController: TableViewController!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    var undoManager: NSUndoManager!

    //MARK: App start up

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        window.delegate = self
        undoManager = NSUndoManager()
        checkForExiftool()
    }

    // let the user know if ExifTool can't be found
    func checkForExiftool() {
        let paths = ["/usr/bin", "/usr/local/bin", "/opt/bin"]
        let fileManager = NSFileManager.defaultManager()
        for path in paths {
            let exiftoolPath = path + "/exiftool"
            if fileManager.fileExistsAtPath(exiftoolPath) {
                AppDelegate.exiftoolPath = exiftoolPath
                println("exiftool path = \(exiftoolPath)")
                return
            }
        }
        let alert = NSAlert()
        alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
        alert.messageText = NSLocalizedString("NO_EXIFTOOL_TITLE",
                                              comment: "can't find exiftool")
        alert.informativeText = NSLocalizedString("NO_EXIFTOOL_DESC",
                                                  comment: "can't find exiftool")
        alert.runModal()
        window.close()
    }

    //MARK: window delegate undo handling

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        return undoManager
    }

    //MARK: window status as a proxy for modifications

    func isModified() -> Bool {
        return window.documentEdited
    }

    func modified(value: Bool) {
        window.documentEdited = value
    }

    //MARK: open panel handling

    @IBAction func showOpenPanel(AnyObject) {
        var panel = NSOpenPanel()
        panel.allowedFileTypes = CGImageSourceCopyTypeIdentifiers() as [AnyObject]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            // expand selected URLs that refer to a directory
            var urls = [NSURL]()
            for url in panel.URLs as! [NSURL] {
                if !tableViewController.filesAddedFromFolder(url, toURLs: &urls) {
                    urls.append(url)
                }
            }
            let dups = tableViewController.addImages(urls)
            if dups {
                let alert = NSAlert()
                alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("WARN_TITLE", comment: "Files not opened")
                alert.informativeText = NSLocalizedString("WARN_DESC", comment: "Files not opened")
                alert.runModal()
            }
        }
    }

    //MARK: Save image changes (if any)

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case Selector("showOpenPanel:"):
            return true
        case Selector("save:"):
            return isModified()
        case Selector("openPreferencesWindow:"):
            return true
        default:
            println("default for item \(menuItem)")
        }
        return false
    }

    @IBAction func save(AnyObject!) {
        if tableViewController.saveAllImages() {
            modified(false)
            undoManager.removeAllActions()
        }
    }

    @IBAction func openPreferencesWindow(sender: AnyObject!) {
        preferences.showWindow(sender)
    }

    //MARK: app termination

    func applicationShouldTerminateAfterLastWindowClosed(theApplication: NSApplication) -> Bool {
        return true
    }
    
    func saveOrDontSave(window: NSWindow) -> Bool {
        if window.documentEdited {
            var alert = NSAlert()
            alert.addButtonWithTitle(NSLocalizedString("SAVE",
                                                       comment: "Save"))
            alert.addButtonWithTitle(NSLocalizedString("CANCEL",
                                                       comment: "Cancel"))
            alert.addButtonWithTitle(NSLocalizedString("DONT_SAVE",
                                                       comment: "Don't Save"))
            alert.messageText = NSLocalizedString("UNSAVED_TITLE",
                                                  comment: "Unsaved Changes")
            alert.informativeText = NSLocalizedString("UNSAVED_DESC",
                                                      comment: "Unsaved Changes")
            alert.beginSheetModalForWindow(window) {
                (response: NSModalResponse) -> Void in
                switch response {
                case NSAlertFirstButtonReturn:      // Save
                    self.save(nil)
                case NSAlertSecondButtonReturn:     // Cancel
                    // Close/terminate cancelled
                    return
                default:
                    // Don't bother saving
                    break
                }
                window.documentEdited = false
                window.close()
            }
            return false
        }
        return true
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        if saveOrDontSave(window) {
            return .TerminateNow
        }
        return .TerminateCancel
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


    /// Window delegate functions

    func windowShouldClose(window: AnyObject) -> Bool {
        return saveOrDontSave(window as! NSWindow)
    }
}
