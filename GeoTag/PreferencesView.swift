//
//  PreferencesView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/29/19.
//  Copyright 2019 Marco S Hyman
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

import Cocoa

// only used for unit testing
var preferencesViewController: PreferencesViewController? = nil

class PreferencesViewController: NSViewController {

    // Populate the preferences outlets with current state

    override func viewWillAppear() {
        super.viewWillAppear()

        preferencesViewController = self
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
    weak var sidecarButton: NSButton!
    
    @IBAction func sidecarButtonChanged(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.set(sender.state == NSControl.StateValue.on,
                     forKey: Preferences.sidecarKey)
        
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
    
    @IBAction
    func setTrackColor(_ sender: NSColorWell) {
        let defaults = UserDefaults.standard
        let data = NSArchiver.archivedData(withRootObject: sender.color)
        defaults.set(data, forKey: Preferences.trackColorKey)
    }
    
    @IBAction
    func close(_ sender: Any) {
        self.view.window?.close()
    }
    
}
