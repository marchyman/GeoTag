//
//  Preferences.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright 2015-2019 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AppKit

final class Preferences : NSWindowController {

    // class constants
    static let nibName = NSNib.Name("Preferences")
    static let saveBookmarkKey = "SaveBookmarkKey"
    static let coordFormatKey = "CoordFormatKey"
    static let sidecarKey = "SidecarKey"
    static let dateTimeGPSKey = "DateTimeGPSKey"
    static let trackColorKey = "TrackColorKey"
    static var checkDirectory = true
    private static var url: URL? = nil
    
    enum CoordFormat: Int {
        case deg
        case degMin
        case degMinSec
    }

    /// fetch the URL of the optional save folder
    /// - Returns: the URL associated with the save directory security bookmark
    ///   if one has been specified
    ///
    /// If a save directory/folder has been specified but does not exist an
    /// alert is shown.
    class
    func saveFolder() -> URL? {
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
                    unexpected(error: error, "Problem locating image backup folder")
                }
                if staleBookmark {
                    unexpected(error: nil, "The specified image backup Folder\n\n\t\(url?.path ?? "[unknown]"))\n\nis missing.  Please select a new backup folder.")
                    url = nil
                }

            }
        }
        return url
    }
    
    class
    func coordFormat() -> CoordFormat {
        let defaults = UserDefaults.standard
        let value = defaults.integer(forKey: coordFormatKey)
        if let format = CoordFormat(rawValue: value) {
            return format
        }
        return .deg
    }

    class
    func useSidecarFiles() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: sidecarKey)
    }

    class
    func dateTimeGPS() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: dateTimeGPSKey)
    }

    class
    func trackColor() -> NSColor {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: trackColorKey),
           let color = NSUnarchiver.unarchiveObject(with: data) {
            return color as! NSColor
        }
        let defaultColor = NSColor.systemBlue
        let data = NSArchiver.archivedData(withRootObject: defaultColor)
        defaults.set(data, forKey: trackColorKey)
        return defaultColor
    }
#if DEBUG
    // debug class function to reset existing defaults
    class
    func resetDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: coordFormatKey)
        defaults.removeObject(forKey: sidecarKey)
        defaults.removeObject(forKey: saveBookmarkKey)
        defaults.removeObject(forKey: dateTimeGPSKey)
        defaults.removeObject(forKey: trackColorKey)
    }
#endif

    @IBOutlet
    var saveFolderPath: NSPathControl!

    /// select a save folder
    /// - Parameter AnyObject: unused
    ///
    /// Allow the user to pick or create a folder where the original
    /// copies of updated images will be saved
    
    @IBAction
    func pickSaveFolder(_: AnyObject) {
        var bookmark: Data? = nil
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal().rawValue == NSFileHandlingPanelOKButton {
            if let url = panel.url {
                do {
                    try bookmark = url.bookmarkData(options: .withSecurityScope)
                    saveFolderPath.url = url
                } catch let error as NSError {
                    unexpected(error: error,
                               "Cannot create security bookmark for image backup folder\n\nReason: ")
                }
                let defaults = UserDefaults.standard
                defaults.set(bookmark, forKey: Preferences.saveBookmarkKey)
                Preferences.checkDirectory = true
            } else {
                unexpected(error: nil,
                           "Cannot create image backup folder\n\nReason: ")
            }
        }
    }

    @IBOutlet weak var coordFormatDeg: NSButton!
    @IBOutlet weak var coordFormatDegMin: NSButton!
    @IBOutlet weak var coordFormatDegMinSec: NSButton!
    
    @IBAction func coordFormatChanged(_ sender: NSButton) {
        if let id = sender.identifier {
            var value = 0
            switch id {
            case NSUserInterfaceItemIdentifier("deg"):
                break
            case NSUserInterfaceItemIdentifier("degMin"):
                value = 1
            case NSUserInterfaceItemIdentifier("degMinSec"):
                value = 2
            default:
                break
            }
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: Preferences.coordFormatKey)
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("CoordFormatChanged"), object: nil)
        }
    }

    @IBOutlet
    weak var dtGPSButton: NSButton!

    @IBAction
    func toggleDateTimeGPS(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.set(sender.state == NSControl.StateValue.on,
                     forKey: Preferences.dateTimeGPSKey)
    }

    @IBOutlet
    weak var trackColorWell: NSColorWell!

    @IBAction func setTrackColor(_ sender: NSColorWell) {
        let defaults = UserDefaults.standard
        let data = NSArchiver.archivedData(withRootObject: sender.color)
        defaults.set(data, forKey: Preferences.trackColorKey)
    }

    @IBOutlet
    weak var sidecarButton: NSButtonCell!
    
    @IBAction func sidecarButtonChanged(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.set(sender.state == NSControl.StateValue.on,
                     forKey: Preferences.sidecarKey)

    }

    /// return the NIB name for this window

	override
    var windowNibName: NSNib.Name? {
		return Preferences.nibName
	}

    /// initialize preferences pane from current user preferences

    override
    func windowDidLoad() {
        saveFolderPath.url = Preferences.saveFolder()
        switch Preferences.coordFormat() {
        case .deg:
            coordFormatDeg.state = NSControl.StateValue.on
        case .degMin:
            coordFormatDegMin.state = NSControl.StateValue.on
        case .degMinSec:
            coordFormatDegMinSec.state = NSControl.StateValue.on
        }
        sidecarButton.state = Preferences.useSidecarFiles() ?
            NSControl.StateValue.on :
            NSControl.StateValue.off
        dtGPSButton.state = Preferences.dateTimeGPS() ?
                            NSControl.StateValue.on :
                            NSControl.StateValue.off
        trackColorWell.color = Preferences.trackColor()
    }

    // window delegate function... orderOut instead of close

    func windowShouldClose(sender: AnyObject!) -> Bool {
        if let window = window {
            window.orderOut(sender)
        }
        return false
    }
}
