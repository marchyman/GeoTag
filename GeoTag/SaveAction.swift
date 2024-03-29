//
//  SaveAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI

extension AppState {

    // return true if the save menu item should be disabled

    func saveDisabled() -> Bool {
        return saveInProgress || !isDocumentEdited
    }

    // Update image files with changed timestamp/location info

    func saveAction() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
        @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false
        @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()

        // returned status of the save operation
        struct SaveStatus {
            let image: ImageModel
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
        let imagesToSave = tvm.images.filter { $0.changed }
        undoManager.removeAllActions()
        isDocumentEdited = false

        // process the images in the background.
        Task {
            @AppStorage(AppSettings.addTagsKey) var addTags = false
            @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
            @AppStorage(AppSettings.finderTagKey) var finderTag = "GeoTag"

            // get the field that won't change from the view model before
            // spinning off new tasks.
            let makeBackup = !doNotBackup
            let url = backupURL
            let tagFiles = addTags
            let tagName = finderTag.isEmpty ? "GeoTag" : finderTag

            await withTaskGroup(of: SaveStatus.self) { group in
                for image in imagesToSave {
                    group.addTask { [self] in
                        @AppStorage(AppSettings.createSidecarFilesKey) var createSidecarFiles = false
                        var errorDescription: String?
                        // saving must occur in the app sandbox.
                        let sandbox: Sandbox
                        do {
                            sandbox = try Sandbox(image)
                            if createSidecarFiles {
                                sandbox.makeSidecarFile()
                            }
                            if makeBackup {
                                try await sandbox.makeBackupFile(backupFolder: url!)
                            }
                            try await sandbox.saveChanges(timeZone: timeZone)
                            if tagFiles {
                                try await sandbox.setTag(name: tagName)
                            }

                        } catch {
                            errorDescription = error.localizedDescription
                        }
                        return SaveStatus(image: image,
                                          error: errorDescription)
                    }
                }

                // Update image original values after update for images
                // with no errors.
                for await status in group {
                    if status.error == nil {
                        let image = status.image
                        image.originalDateTimeCreated = image.dateTimeCreated
                        image.originalLocation = image.location
                        image.originalElevation = image.elevation
                    } else {
                        saveIssues.updateValue(status.error!,
                                               forKey: status.image.id)
                    }
                }
            }

            if !saveIssues.isEmpty {
                isDocumentEdited = true
                addSheet(type: .saveErrorSheet)
            }
            saveInProgress = false
        }
    }
}
