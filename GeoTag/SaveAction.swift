//
//  SaveAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

extension AppViewModel {

    // return true if the save menu item should be disabled

    func saveDisabled() -> Bool {
        return saveInProgress || !(mainWindow?.isDocumentEdited ?? false)
    }

    // Update image files with changed timestamp/location info

    func saveAction() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
        @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false
        @AppStorage(AppSettings.saveBookmarkKey) var saveBookmark = Data()

        let cvm = ContentViewModel.shared

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
            cvm.addSheet(type: .noBackupFolderSheet)
            return
        }

        // copy images.  The info in the copies will be saved in background
        // tasks.
        saveInProgress = true
        cvm.saveIssues = [:]
        let imagesToSave = images
        undoManager.removeAllActions()
        mainWindow?.isDocumentEdited = false

        // process the images in the background.
        Task {
            @AppStorage(AppSettings.addTagKey) var addTag = false
            @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
            @AppStorage(AppSettings.tagKey) var tag = "GeoTag"

            // get the field that won't change from the view model before
            // spinning off new tasks.
            let makeBackup = !doNotBackup
            let url = backupURL
            let tagFiles = addTag
            let tagName = tag.isEmpty ? "GeoTag" : tag

            await withTaskGroup(of: SaveStatus.self) { group in
                for image in imagesToSave where image.changed {
                    group.addTask { [self] in
                        @AppStorage(AppSettings.createSidecarFileKey) var createSidecarFile = false
                        var errorDescription: String?
                        // saving must occur in the app sandbox.
                        let sandbox: Sandbox
                        do {
                            sandbox = try Sandbox(image)
                            if makeBackup {
                                try await sandbox.makeBackupFile(backupFolder: url!)
                            }
                            try await sandbox.saveChanges(timeZone: timeZone,
                                                          createSidecarFile: createSidecarFile)
                            if tagFiles {
                                try await sandbox.setTag(name: tagName)
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

                // Update image original values after update for images
                // with no errors.
                for await status in group {
                    if status.error == nil {
                        self[status.id].originalDateTimeCreated = status.dateTimeCreated
                        self[status.id].originalLocation = status.location
                        self[status.id].originalElevation = status.elevation
                    } else {
                        cvm.saveIssues.updateValue(status.error!, forKey: status.id)
                    }
                }
            }

            if !cvm.saveIssues.isEmpty {
                DispatchQueue.main.async {
                    self.mainWindow?.isDocumentEdited = true
                }
                cvm.addSheet(type: .saveErrorSheet)
            }
            saveInProgress = false
        }
    }
}
