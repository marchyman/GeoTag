import Foundation
import SwiftUI

extension GeoTagReducer {
    func getBackupURL(_ state: inout GeoTagState) {
        @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()
        var staleBookmark = false

        let url = try? URL(resolvingBookmarkData: savedBookmark,
                           options: [.withoutUI, .withSecurityScope],
                           bookmarkDataIsStale: &staleBookmark)
        state.backupURL = url
        if let url, staleBookmark {
            newBackupFolder(&state, url: url)
        }
    }

    func checkBackupFolderSize(_ state: inout GeoTagState) {
        guard let url = state.backupURL else { return }

        let propertyKeys: Set = [
            URLResourceKey.totalFileSizeKey,
            .addedToDirectoryDateKey
        ]
        let fileManager = FileManager.default
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        guard let urlEnumerator =
            fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: Array(propertyKeys),
                options: [.skipsHiddenFiles],
                errorHandler: nil) else { return }
        guard let sevenDaysAgo =
            Calendar.current.date(
                byAdding: .day, value: -7,
                to: Date()) else { return }

        // starting state
        state.oldFiles = []
        state.folderSize = 0
        state.deletedSize = 0

        // loop through the files accumulating storage requirements and a count
        // of older files
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            guard let resources =
                    try? fileUrl.resourceValues(forKeys: propertyKeys),
                let fileSize = resources.totalFileSize,
                let fileDate = resources.addedToDirectoryDate else { break }
            state.folderSize += fileSize
            if fileDate < sevenDaysAgo {
                state.oldFiles.append(fileUrl)
                state.deletedSize += fileSize
            }
        }
    }

    // remove the files listed in the oldFiles array and clear the array

    nonisolated func removeFiles(filesToRemove: [URL], from folder: URL?) {
        guard let folder else { return }
        Task {
            _ = folder.startAccessingSecurityScopedResource()
            defer { folder.stopAccessingSecurityScopedResource() }
            let fileManager = FileManager.default
            for url in filesToRemove {
                do {
                    try fileManager.removeItem(at: url)
                } catch {
                    logger.error(
                        """
                        Failed to remove \(url, privacy: .public): \
                        \(error.localizedDescription, privacy: .public)")
                        """)
                }
            }
        }

    }

    func newBackupFolder(_ state: inout GeoTagState, url: URL?) {
        @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()

        if let url {
            do {
                try savedBookmark = url.bookmarkData(options: .withSecurityScope)
                state.backupURL = url
                checkBackupFolderSize(&state)
           } catch {
                state.backupURL = nil
                state.addSheet(
                    type: .unexpectedErrorSheet,
                    error: error.localizedDescription,
                    message: """
                        Error creating security scoped bookmark for backup \
                        location \(url.path)
                        """
                )
            }
        } else {
            savedBookmark = Data()
        }
    }
}
