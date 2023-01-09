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
        return !(window?.isDocumentEdited ?? false)
    }

    // Update image files with changed timestamp/location info

    func saveAction() {

        // returned status of the save operation

        struct SaveStatus {
            let id: ImageModel.ID
            let error: String?
        }

        // copy images.  The info in the copies will be saved in background
        // tasks.

        saveInProgress = true
        let imagesToSave = images
        undoManager.removeAllActions()
        window?.isDocumentEdited = false

        // process the images in the background.

        Task {
            await withTaskGroup(of: SaveStatus.self) { group in
                for image in imagesToSave {
                    group.addTask {
                        // pretend we did a save for now
                        try? await Task.sleep(for: .seconds(2))
                        return SaveStatus(id: image.id, error: nil)
                    }
                }
                for await status in group {
                    // check for errors here
                    self[status.id].setOriginalValues()
                }
            }

            saveInProgress = false
        }
    }
}

