//
//  AppDelegate.swift
//  GeoTag (3rd version)
//
//  Created by Marco S Hyman on 6/11/14.
//  Copyright (c) 2014, 2015 Marco S Hyman, CC-BY-NC
//

import Foundation
import AppKit

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    // class variable holds path to exiftool
    lazy var preferences: Preferences = Preferences()
    lazy var undoManager: UndoManager = UndoManager()

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

    //MARK: App start up

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window.delegate = self
        if Preferences.saveFolder() == nil {
            perform(#selector(openPreferencesWindow(_:)), with: nil, afterDelay: 0)
        }
    }

   //MARK: window delegate undo handling

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
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
        // first (rightmost button) is the Open button
        let openButton = NSApplication.ModalResponse.alertFirstButtonReturn
        if panel.runModal() == openButton {
            // expand selected URLs that refer to a directory
            var urls = [URL]()
            for url in panel.urls {
                if !addUrlsInFolder(url: url, toUrls: &urls) {
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

    //MARK: Save image changes (if any)

    @objc func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else { return false }
        switch action {
        case #selector(showOpenPanel(_:)):
            return true
        case #selector(save(_:)):
            return modified
        case #selector(openPreferencesWindow(_:)):
            return true
        default:
            print("default for item \(item)")
        }
        return false
    }

    /// action bound to File -> Save
    /// - Parameter AnyObject: unused
    ///
    /// Save all images with updated geolocation information and clear all
    /// undo actions.
    @IBAction func save(_: AnyObject?) {
        if tableViewController.saveAllImages() {
            modified = false
            undoManager.removeAllActions()
        }
    }

    @IBAction func openPreferencesWindow(_ sender: AnyObject!) {
        preferences.showWindow(sender)
    }

    //MARK: app termination

    func applicationShouldTerminateAfterLastWindowClosed(_ theApplication: NSApplication) -> Bool {
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
                (response: NSApplication.ModalResponse) -> Void in
                switch response {
                case NSApplication.ModalResponse.alertFirstButtonReturn:      // Save
                    self.save(nil)
                case NSApplication.ModalResponse.alertSecondButtonReturn:     // Cancel
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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
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
    func windowShouldClose(_: NSWindow) -> Bool {
        return saveOrDontSave()
    }
}
