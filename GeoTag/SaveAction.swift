//
//  SaveAction.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import Foundation

extension ViewModel {
    // return true if the save menu item should be disabled
    func saveDisabled() -> Bool {
        return saveInProgress || !(window?.isDocumentEdited ?? false)
    }

    // Update image files with changed timestamp/location info

    func saveAction() {

        // returned status of the save operation

        struct SaveStatus {
            let id: ImageModel.ID
            let dateTimeCreated: String?
            let location: Coords?
            let elevation: Double?
            let error: String?
        }

        // copy images.  The info in the copies will be saved in background
        // tasks.

        saveInProgress = true
        saveIssues = [:]
        let imagesToSave = images
        undoManager.removeAllActions()
        window?.isDocumentEdited = false

        // process the images in the background.

        Task {
            await withTaskGroup(of: SaveStatus.self) { group in
                for image in imagesToSave {
                    // only process images that have changed
                    if image.changed {
                        group.addTask {
                            var errorDescription: String? = nil
                            do {
                                try await image.saveChanges(timeZone: self.timeZone)
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

                // Update image original values after update when no errors

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

