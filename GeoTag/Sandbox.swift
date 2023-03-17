//
//  Sandbox.swift
//  GeoTag
//
//  Created by Marco S Hyman on 3/16/23.
//

import SwiftUI

// The image model with additional URLs that reference the files relative
// to the application sandbox.

struct Sandbox {
    let image: ImageModel
    let imageURL: URL               // symbolic link in sandbox
    let sidecarURL: URL             // symbolic link in sandbox
    let xmpPresenter: XmpPresenter

    init(_ image: ImageModel) throws {
        self.image = image
        // create a folder with a unique id in the sandbox
        let fileManager = FileManager.default
        let uuid = UUID().uuidString
        let docDir = try fileManager.url(for: .documentDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true)
        let imageDir = docDir.appendingPathComponent(uuid, isDirectory: true)
        try fileManager.createDirectory(at: imageDir,
                                        withIntermediateDirectories: true)

        // create a symbolic link to the image in the folder
        self.imageURL = imageDir.appendingPathComponent(image.fileURL.lastPathComponent)
        try fileManager.createSymbolicLink(at: imageURL,
                                           withDestinationURL: image.fileURL)

        // create a symbolic link to the sidecar file in the folder
        self.sidecarURL = imageDir.appendingPathComponent(image.sidecarURL.lastPathComponent)
        try fileManager.createSymbolicLink(at: sidecarURL,
                                           withDestinationURL: image.sidecarURL)

        // create an NSFilePresenter for the symbolic links
        xmpPresenter = XmpPresenter(for: imageURL)
    }

    enum BackupError: Error {
        case backupError(String)
    }

    // Modify name for backup file. Add a suffix to the name until no file
    // is found at the save location

    private func backupName(for name: String, in backupFolder: URL) -> URL {
        let fileManager = FileManager.default
        var fileNumber = 1
        var saveFileURL = backupFolder.appendingPathComponent(name, isDirectory: false)

        // enable access to backupFolder
        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        // loop until there is no file at the backup location with the
        // calculated URL
        while fileManager.fileExists(atPath: (saveFileURL.path)) {
            var newName = name
            let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            saveFileURL = backupFolder.appendingPathComponent(newName, isDirectory: false)
        }
        return saveFileURL
    }

    // Copy a sidecar file into the backup folder. The copy is done this
    // way as otherise a copy of of related item (sidecar file) to a
    // security scoped folder using FileManager's copyItem(at:to:) throws
    // an error.

    func makeSidecarBackup(_ backupFolder: URL) throws {
        let fileName = image.sidecarURL.lastPathComponent
        let saveFileURL = backupName(for: fileName, in: backupFolder)

        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        NSFileCoordinator.addFilePresenter(image.xmpPresenter)
        defer { NSFileCoordinator.removeFilePresenter(image.xmpPresenter) }

        guard let data = image.xmpPresenter.readData() else {
            throw BackupError.backupError("Sidecar \(fileName) copy failed!")
        }
        try data.write(to: saveFileURL)
    }

    // copy an image file into the backup folder.  Because copyItems doesn't
    // follow symbolic links reference the original file instead of using
    // the link in the sandbox.

    func makeBackupFile(backupFolder: URL) async throws {
        // sidecar files get special handling

        if image.sidecarExists {
            try makeSidecarBackup(backupFolder)
            return
        }

        let fileName = image.fileURL.lastPathComponent
        let saveFileURL = backupName(for: fileName, in: backupFolder)

        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        // Copy the image file to the backup folder
        let fileManager = FileManager.default
        try fileManager.copyItem(at: image.fileURL, to: saveFileURL)

        // belts and suspenders: verify the copy happened.  There once was
        // a macOS bug where the copy failed but no error was reported.
        if !fileManager.fileExists(atPath: saveFileURL.path) {
            throw BackupError.backupError("Image \(fileName) copy failed!")
        }
    }

    // use exiftool to save metadata changes to the image file

    func saveChanges(timeZone: TimeZone?) async throws {
        @AppStorage(AppSettings.createSidecarFileKey) var createSidecarFile = false

        NSFileCoordinator.addFilePresenter(xmpPresenter)
//        if createSidecarFile && !sidecarExists {
//            // create a sidecar file for this image.
//            Exiftool.helper.makeSidecar(from: self)
//        }
        try await Exiftool.helper.update(from: self, timeZone: timeZone)
        NSFileCoordinator.removeFilePresenter(xmpPresenter)
    }

    // add a Finder tag to the image file

    func setTag(name: String) async throws {
        var tagValues: [String]
        let tags = try imageURL.resourceValues(forKeys: [.tagNamesKey])
        if let tagNames = tags.tagNames {
            tagValues = tagNames
            if tagValues.contains(name) {
                return
            }
            tagValues.append(name)
        } else {
            tagValues = [name]
        }
        let url = imageURL as NSURL
        try url.setResourceValue(tagValues, forKey: .tagNamesKey)
    }

}
