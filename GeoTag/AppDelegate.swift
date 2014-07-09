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


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        window.delegate = self
        // debug code
        let id1 = ImageData(path: NSURL(string: "file:///Users/marc/Desktop/p-141711415-1432.jpg"))
        let id2 = ImageData(path: NSURL(string: "file:///Users/marc/Desktop/p-141660942-1403.raf"))
    }

    /*
     * app termination
     */
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
                println("Modal response is \(response)")
                switch response {
                case NSAlertFirstButtonReturn:      // Save
                    println("initiate save here")
                case NSAlertSecondButtonReturn:     // Cancel
                    println("Close/terminate cancelled")
                    return
                default:
                    println("Don't bother saving")
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
        println("applicationShouldTerminate called")
        if saveOrDontSave(window) {
            return .TerminateNow
        }
        return .TerminateCancel
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    /*
     * Window delegate functions
     */
    func windowShouldClose(window: NSWindow) -> Bool {
        println("windowShouldClose: \(window)")
        return saveOrDontSave(window)
    }
}
