//
//  SaveFolder.swift
//  GeoTag
//
//  Created by Marco S Hyman on 2/8/20.
//  Copyright © 2020 Marco S Hyman. All rights reserved.
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

/// Check the  folder used to save backups for old image files.  Also check the total size of backed up
/// image files.  Remind the user  that old backups can be deleted if any files were added to the
/// directory more than 7 days prior to the current date or if the backup folder contains more than 500 MB
/// of backuop images.  The numbers 7 and 500 MB are completely arbitrary, although any file older than
/// 7 days will be on a time machine backup provided
/// 1) time machine is in use; and
/// 2) the backup folder is being saved to time machine.
///
/// - Parameter _: The URL of the folder containing backups

func checkSaveFolder(_ url: URL) {
    let propertyKeys: Set = [URLResourceKey
                                .totalFileSizeKey,
                                .addedToDirectoryDateKey]
    let fileManager = FileManager.default
    let _ = url.startAccessingSecurityScopedResource()
    defer { url.stopAccessingSecurityScopedResource() }
    guard let urlEnumerator =
        fileManager.enumerator(at: url,
                               includingPropertiesForKeys: Array(propertyKeys),
                               options: [.skipsHiddenFiles],
                               errorHandler: nil) else { return }
    // loop through the files accumulating storage requirements and a count
    // of older files
    guard let sevenDaysAgo =
        Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return }
    var oldFiles = 0
    var folderSize = 0
    while let fileUrl = urlEnumerator.nextObject() as? URL {
        guard
            let resources =
                try? fileUrl.resourceValues(forKeys: propertyKeys),
                let fileSize = resources.totalFileSize,
                let fileDate = resources.addedToDirectoryDate else { break }
        folderSize += fileSize
        if fileDate < sevenDaysAgo {
            oldFiles += 1
        }
    }
    
    // Alert if there are any old files or the folder size exceeds 500,000 MB
    let folderLimit = 500_000_000_000
    if folderSize > folderLimit || oldFiles > 1 {
        let messageStr = String(format: NSLocalizedString("CLEAN_SAVE_FOLDER",
                                                          comment: "clean save folder"),
                                url.path, folderSize / 1_000_000, oldFiles)
        let alert = NSAlert()
        alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
        alert.messageText = NSLocalizedString("CLEAN_SAVE_FOLDER_TITLE",
                                              comment:"Clean Save Folder?")
        alert.informativeText = messageStr;
        alert.runModal()
    }
}

private
func oldFilesAlert() {
    
}
