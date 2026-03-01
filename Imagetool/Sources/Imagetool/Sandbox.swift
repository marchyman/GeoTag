import Exiftool
import Metadata
import SwiftUI

// Image URLs reference their files relative to the application sandbox.
// Exiftool must do its work inside the sandbox as it creates temporary files.
// macOS does not allow creation of files in folders unless folder access
// is explicitly allowed by the user.

public struct Sandbox {
    let orgURL: URL
    let imgDir: URL
    let imgURL: URL
    let xmpURL: URL
    let xmpPresenter: XmpPresenter

    public init(for url: URL) throws {
        orgURL = url
        let sidecar = url.deletingPathExtension()
                         .appendingPathExtension(xmpExtension)

        let fileManager = FileManager.default
        let uuid = UUID().uuidString
        imgDir = URL.documentsDirectory
                    .appendingPathComponent(uuid, isDirectory: true)
        try fileManager.createDirectory(at: imgDir,
                                        withIntermediateDirectories: true)

        // create symbolic links to the image and xmp file in the folder
        imgURL = imgDir.appendingPathComponent(url.lastPathComponent)
        try fileManager.createSymbolicLink(at: imgURL,
                                           withDestinationURL: url)

        xmpURL = imgDir.appendingPathComponent(sidecar.lastPathComponent)
        try fileManager.createSymbolicLink(at: xmpURL,
                                           withDestinationURL: sidecar)

        // create an NSFilePresenter for the symbolic links
        xmpPresenter = XmpPresenter(for: imgURL, sidecar: xmpURL)
    }

    public var sidecarExists: Bool {
        FileManager.default.fileExists(atPath: xmpURL.path)
    }

    enum BackupError: Error {
        case backupError(String)
    }
}

// Function to remove a sandbox's imgDir

extension Sandbox {
    public func removeSandboxFolder() {
        do {
            try FileManager.default.removeItem(at: imgDir)
        } catch {
            Imagetool.logger.error("\(#function): \(error.localizedDescription, privacy: .public)")
        }
    }
}

// Create a sidecar file in the sandbox.

extension Sandbox {
    public func makeSidecarFile() throws {
        NSFileCoordinator.addFilePresenter(xmpPresenter)
        defer {
            NSFileCoordinator.removeFilePresenter(xmpPresenter)
        }
        try Exiftool.helper.makeSidecar(from: imgURL)
    }
}

// image and sidecar backup functions

extension Sandbox {

    // copy an image file into the backup folder.  Because copyItems doesn't
    // follow symbolic links reference the original file instead of using
    // the link in the sandbox.

    public func makeBackupFile(backupFolder: URL) async throws {
        // sidecar files get special handling

        if sidecarExists {
            try await makeSidecarBackup(backupFolder)
            return
        }

        let fileName = orgURL.lastPathComponent
        let saveFileURL = backupName(for: fileName, in: backupFolder)

        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        // Copy the image file to the backup folder
        let fileManager = FileManager.default
        try fileManager.copyItem(at: orgURL, to: saveFileURL)

        // belts and suspenders: verify the copy happened.  There once was
        // a macOS bug where the copy failed but no error was reported.
        if !fileManager.fileExists(atPath: saveFileURL.path) {
            throw BackupError.backupError("Image \(fileName) copy failed!")
        }
    }

    // Copy a sidecar file into the backup folder. The copy is done this
    // way as otherise a copy of of related item (sidecar file) to a
    // security scoped folder using FileManager's copyItem(at:to:) throws
    // an error.

    public func makeSidecarBackup(_ backupFolder: URL) async throws {
        let fileName = imgURL.deletingPathExtension()
                             .appendingPathExtension(xmpExtension)
                             .lastPathComponent
        let saveFileURL = backupName(for: fileName, in: backupFolder)

        _ = backupFolder.startAccessingSecurityScopedResource()
        defer { backupFolder.stopAccessingSecurityScopedResource() }

        NSFileCoordinator.addFilePresenter(xmpPresenter)
        defer { NSFileCoordinator.removeFilePresenter(xmpPresenter) }

        guard let data = xmpPresenter.readData() else {
            throw BackupError.backupError("Sidecar \(fileName) copy failed!")
        }
        try data.write(to: saveFileURL)
    }

    // Modify name for backup file. Add a suffix to the name until no file
    // is found at the save location

    private func backupName(for name: String, in backupFolder: URL) -> URL {
        let fileManager = FileManager.default
        var fileNumber = 1
        var saveFileURL = backupFolder.appendingPathComponent(name,
                                                              isDirectory: false)

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
            saveFileURL = backupFolder.appendingPathComponent(
                newName, isDirectory: false)
        }
        return saveFileURL
    }
}

// metadata and finder updates

extension Sandbox {

    // use exiftool to save metadata changes to the image file

    public func saveChanges(from metadata: Metadata,
                            timeZone: TimeZone?) async throws {
        NSFileCoordinator.addFilePresenter(xmpPresenter)
        defer { NSFileCoordinator.removeFilePresenter(xmpPresenter) }
        try await Exiftool.helper.update(image: imgURL,
                                         from: metadata,
                                         timeZone: timeZone)
    }

    // add a Finder tag to the image file

    public func setTag(name: String) async throws {
        var tagValues: [String]
        let tags = try orgURL.resourceValues(forKeys: [.tagNamesKey])
        if let tagNames = tags.tagNames {
            tagValues = tagNames
            if tagValues.contains(name) {
                return
            }
            tagValues.append(name)
        } else {
            tagValues = [name]
        }
        let url = orgURL as NSURL
        try url.setResourceValue(tagValues, forKey: .tagNamesKey)
    }
}
