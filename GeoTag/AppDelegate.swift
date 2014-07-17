//
//  AppDelegate.swift
//  GeoTag (3rd version)
//
//  Created by Marco S Hyman on 6/11/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
                            
    @IBOutlet var window: NSWindow
    @IBOutlet var tableViewController: TableViewController
    @IBOutlet var progressIndicator: NSProgressIndicator

    /// App start up

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        window.delegate = self
    }

    /// window status as a proxy for modifications

    func isModified() -> Bool {
        return window.documentEdited
    }

    func modified(value: Bool) {
        window.documentEdited = value
    }

    /// open panel handling

    @IBAction func showOpenPanel(AnyObject) {
        var panel = NSOpenPanel()
        panel.allowedFileTypes = CGImageSourceCopyTypeIdentifiers()?.takeUnretainedValue()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == NSFileHandlingPanelOKButton {
            progressIndicator.startAnimation(self)
            let dups = tableViewController.addImages(panel.URLs as [NSURL])
            progressIndicator.stopAnimation(self)
            if dups {
                let alert = NSAlert()
                alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("WARN_TITLE", comment: "Files not opened")
                alert.informativeText = NSLocalizedString("WARN_DESC", comment: "Files not opened")
                alert.runModal()
            }
        }
    }

    /// app termination

    func applicationShouldTerminateAfterLastWindowClosed(theApplication: NSApplication!) -> Bool {
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
                    // initiate save ;;;
                    println("initiate save here")
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

    func applicationShouldTerminate(sender: NSApplication!) -> NSApplicationTerminateReply {
        if saveOrDontSave(window) {
            return .TerminateNow
        }
        return .TerminateCancel
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }


    /// Window delegate functions

    func windowShouldClose(window: NSWindow) -> Bool {
        return saveOrDontSave(window)
    }
}
