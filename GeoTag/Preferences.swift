//
//  Preferences.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/7/15.
//  Copyright 2015-2020 Marco S Hyman
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

final class Preferences  {

    // class constants
    static let saveBookmarkKey = "SaveBookmarkKey"
    static let coordFormatKey = "CoordFormatKey"
    static let sidecarKey = "SidecarKey"
    static let dateTimeGPSKey = "DateTimeGPSKey"
    static let trackColorKey = "TrackColorKey"
    static let trackWidthKey = "TrackWidthKey"

    static var checkDirectory = true
    private static var url: URL? = nil
    
    // how does the user desire to see latitudes and longitudes
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
                    checkSaveFolder(url!)
                } catch let error as NSError {
                    unexpected(error: error,
                               NSLocalizedString("MISSING_BACKUP_FOLDER",
                                                 comment: "Problem locating image backup folder"))
                    staleBookmark = false
                    url = nil
                }
                if staleBookmark {
                    let errString = String(format: NSLocalizedString("STALE_BACKUP_FOLDER",
                                           comment: "stale backup folder"), "\(url?.path ?? "[unknown]")")
                    
                    unexpected(error: nil, errString)
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
    
    class
    func trackWidth() -> Double {
        let defaults = UserDefaults.standard
        let trackWidth = defaults.double(forKey: trackWidthKey)
        return trackWidth
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
        defaults.removeObject(forKey: trackWidthKey)
    }
#endif

}
