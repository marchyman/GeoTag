//
//  AppDelegate.swift
//  GeoTag (3rd version)
//
//  Created by Marco S Hyman on 6/11/14.
//  Copyright (c) 2014, 2015 Marco S Hyman, CC-BY-NC
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    // class variable holds path to exiftool
    static private(set) var exiftoolPath: String!
    lazy var preferences: Preferences = Preferences(windowNibName: Preferences.nibName)

    var modified: Bool {
        get {
            return window.isDocumentEdited
        }
        set {
            window.isDocumentEdited = newValue
        }
    }

    @IBOutlet var window: NSWindow!
    @IBOutlet var tableViewController: TableViewController!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    var undoManager: NSUndoManager!

    //MARK: App start up

    func applicationDidFinishLaunching(_ aNotification: NSNotification) {
        // Insert code here to initialize your application
        window.delegate = self
        undoManager = NSUndoManager()
        checkForExiftool()
    }

    /// verify that exiftool can be found.  If exiftool can not be found in one
    /// of the normal locations put up an alert and terminate the program.
    func checkForExiftool() {
        let fileManager = NSFileManager.defaultManager()
        for path in exiftoolSearchPaths() {
            let exiftoolPath = path + "/exiftool"
            if fileManager.fileExists(atPath: exiftoolPath) {
                precondition (AppDelegate.exiftoolPath == nil)
                AppDelegate.exiftoolPath = exiftoolPath
                print("exiftool path = \(exiftoolPath)")
                return
            }
        }
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
            showSetExiftoolPathDialog()
        default:
            window.close()
        }
    }

    func showSetExiftoolPathDialog() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.showsHiddenFiles = true
        switch (openPanel.runModal()) {
        case NSFileHandlingPanelOKButton:
            if let path = openPanel.url?.path {
                let defaults = NSUserDefaults.standard()
                defaults.set(path, forKey: Preferences.exiftoolPathKey)
                defaults.synchronize()
            }
            checkForExiftool()
        default:
            window.close()
        }
    }

    func exiftoolSearchPaths() -> [String] {
        var paths = ["/usr/bin", "/usr/local/bin", "/opt/bin"]
        let defaults = NSUserDefaults.standard()
        if let customPath = defaults.string(forKey: Preferences.exiftoolPathKey) {
            paths.append(customPath)
        }
        return paths
    }

    //MARK: window delegate undo handling

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        return undoManager
    }

    //MARK: open panel handling

    /// action bound to File -> Open
    /// - Parameter AnyObject: unused
    ///
    /// Allows selection of image files and/or directories.  If a directory
    /// is selected all files within the directory and any enclosed sub-directories
    /// will be added to the table of images.  The same file can not be added
    /// to the table multiple times.   If duplicates are detected the user
    /// will be alerted that some files were not opened.
    @IBAction func showOpenPanel(_: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = CGImageSourceCopyTypeIdentifiers() as? [String]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        if panel.runModal() == NSFileHandlingPanelOKButton {
            // expand selected URLs that refer to a directory
            var urls = [NSURL]()
            for url in panel.urls {
                if !addURLsInFolder(url: url, toUrls: &urls) {
                    urls.append(url)
                }
            }
            let dups = tableViewController.addImages(urls: urls)
            if dups {
                let alert = NSAlert()
                alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("WARN_TITLE", comment: "Files not opened")
                alert.informativeText = NSLocalizedString("WARN_DESC", comment: "Files not opened")
                alert.runModal()
            }
        }
    }

    // MARK: Save image changes (if any)

    func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem!) -> Bool {
        guard let action = anItem?.action() else { return false }
        switch action {
        case #selector(showOpenPanel(_:)):
            return true
        case #selector(save(_:)):
            return modified
        case #selector(openPreferencesWindow(_:)):
            return true
        default:
            print("default for item \(anItem)")
        }
        return false
    }

    /// action bound to File -> Save
    /// - Parameter AnyObject: unused
    ///
    /// Save all images with updated geolocation information and clear all
    /// undo actions.
    @IBAction func save(_: AnyObject?) {
        tableViewController.saveAllImages()
        modified = false
        undoManager.removeAllActions()
    }

    @IBAction func openPreferencesWindow(_ sender: AnyObject!) {
        preferences.showWindow(sender)
    }

    //MARK: app termination

    func applicationShouldTerminateAfterLastWindowClosed(theApplication: NSApplication) -> Bool {
        return true
    }

    /// Give the user a chance to save changes
    /// - Returns: true if all changes have been saved, false otherwise
    ///
    /// Alert the user if there are unsaved geo location changes and allow
    /// the user to save or discard the changes before terminating the
    /// application. The user can also cancel program termination without
    /// saving any changes.
    func saveOrDontSave() -> Bool {
        if modified {
            let alert = NSAlert()
            alert.addButton(withTitle: NSLocalizedString("SAVE",
                                                         comment: "Save"))
            alert.addButton(withTitle: NSLocalizedString("CANCEL",
                                                         comment: "Cancel"))
            alert.addButton(withTitle: NSLocalizedString("DONT_SAVE",
                                                         comment: "Don't Save"))
            alert.messageText = NSLocalizedString("UNSAVED_TITLE",
                                                  comment: "Unsaved Changes")
            alert.informativeText = NSLocalizedString("UNSAVED_DESC",
                                                      comment: "Unsaved Changes")
            alert.beginSheetModal(for: window) {
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
                self.modified = false
                self.window.close()
            }
            return false
        }
        return true
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        if saveOrDontSave() {
            return .terminateNow
        }
        return .terminateCancel
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

/// Window delegate functions

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_: AnyObject) -> Bool {
        return saveOrDontSave()
    }
}
