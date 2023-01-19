//
//  SaveAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

extension ViewModel {

    // return true if the save menu item should be disabled

    func saveDisabled() -> Bool {
        return saveInProgress || !(mainWindow?.isDocumentEdited ?? false)
    }

    // Update image files with changed timestamp/location info

    func saveAction() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
        @AppStorage(AppSettings.addTagKey) var addTag = false
        @AppStorage(AppSettings.tagKey) var tag = "GeoTag"

        // returned status of the save operation
        struct SaveStatus {
            let id: ImageModel.ID
            let dateTimeCreated: String?
            let location: Coords?
            let elevation: Double?
            let error: String?
        }

        // before starting check that image files backups are disabled
        // or the image backup folder exists.
        guard doNotBackup || backupURL != nil else {
            addSheet(type: .noBackupFolderSheet)
            return
        }

        // copy images.  The info in the copies will be saved in background
        // tasks.
        saveInProgress = true
        saveIssues = [:]
        let imagesToSave = images
        undoManager.removeAllActions()
        mainWindow?.isDocumentEdited = false

        // process the images in the background.
        Task {
            // get the field that won't change from the view model before
            // spinning off new tasks.
            let makeBackup = !doNotBackup
            let url = backupURL
            let tagFiles = addTag
            let tagName = tag.isEmpty ? "GeoTag" : tag

            await withTaskGroup(of: SaveStatus.self) { group in
                for image in imagesToSave {
                    // only process images that have changed
                    if image.changed {
                        group.addTask { [self] in
                            var errorDescription: String? = nil
                            do {
                                if makeBackup {
                                    try await image.makeBackupFile(backupFolder: url!)
                                }
                                try await image.saveChanges(timeZone: timeZone)
                                if tagFiles {
                                    try await image.setTag(name: tagName)
                                }
                            } catch {
                                errorDescription = error.localizedDescription
                            }
                            return SaveStatus(id: image.id,
                                              dateTimeCreated: image.dateTimeCreated,
                                              location: image.location,
                                              elevation: image.elevation,
                                              error: errorDescription)
                        }
                    }
                }

                // Update image original values after update for images
                // with no errors.
                for await status in group {
                    if status.error == nil {
                        self[status.id].originalDateTimeCreated = status.dateTimeCreated
                        self[status.id].originalLocation = status.location
                        self[status.id].originalElevation = status.elevation
                    } else {
                        saveIssues.updateValue(status.error!, forKey: status.id)
                    }
                }
            }

            if !saveIssues.isEmpty {
                addSheet(type: .saveErrorSheet)
            }
            saveInProgress = false
        }
    }
}

