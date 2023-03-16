//
//  ImageModelSaveChanges.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/9/23.
//

import SwiftUI

extension ImageModel {

    enum BackupError: Error {
        case backupError(String)
    }

    // make a backup of self into the folder identifed by the given URL

    func makeBackupFile(backupFolder: URL) async throws {
        let url: URL

        if sidecarExists {
            url = sidecarURL
            NSFileCoordinator.addFilePresenter(xmpPresenter)
        } else {
            url = fileURL
        }
        let name = url.lastPathComponent

        var fileNumber = 1
        var saveFileURL = backupFolder.appendingPathComponent(name, isDirectory: false)
        let fileManager = FileManager.default
        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        // add a suffix to the name until no file is found at the save location
        while fileManager.fileExists(atPath: (saveFileURL.path)) {
            var newName = name
            let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            saveFileURL = backupFolder.appendingPathComponent(newName, isDirectory: false)
        }

        // Copy the image file to the backup folder
        try fileManager.copyItem(at: url, to: saveFileURL)
        if sidecarExists {
            NSFileCoordinator.removeFilePresenter(xmpPresenter)
        }

        // belts and suspenders: verify the copy happened.  There once was
        // a macOS bug where the copy failed but no error was reported.
        if !fileManager.fileExists(atPath: saveFileURL.path) {
            throw BackupError.backupError("Image \(name) copy failed!")
        }
    }

    // use exiftool to save metadata changes to the image file

    func saveChanges(timeZone: TimeZone?) async throws {
        @AppStorage(AppSettings.createSidecarFileKey) var createSidecarFile = false

        NSFileCoordinator.addFilePresenter(xmpPresenter)
        if createSidecarFile && !sidecarExists {
            // create a sidecar file for this image.
            Exiftool.helper.makeSidecar(from: self)
        }
        try await Exiftool.helper.update(from: self, timeZone: timeZone)
        NSFileCoordinator.removeFilePresenter(xmpPresenter)
    }

    // add a Finder tag to the image file

    func setTag(name: String) async throws {
        var tagValues: [String]
        let tags = try fileURL.resourceValues(forKeys: [.tagNamesKey])
        if let tagNames = tags.tagNames {
            tagValues = tagNames
            if tagValues.contains(name) {
                return
            }
            tagValues.append(name)
        } else {
            tagValues = [name]
        }
        let url = fileURL as NSURL
        try url.setResourceValue(tagValues, forKey: .tagNamesKey)
    }
}
