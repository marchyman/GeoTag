import Foundation
import ImageData
import OSLog
import SwiftUI
import UDF

// initiate processing of the given array of URLs. Get the full list
// of unique urls and save it for the next step.

extension GeoTagReducer {
    func openFiles(_ state: inout GeoTagState, urls: [URL]) {
        // Needed to access when using the fileImporter
        for url in urls where url.startAccessingSecurityScopedResource() {
            state.scopedURLs.append(url)
        }

        // Get all requested URLs
        let imageURLs = urls.flatMap { url in
            isFolder(url) ? urlsIn(folder: url) : [url]
        }

        // check for duplicates of URLs already known
        let processed = Set(state.imageData.map { $0.fullPath })
        let duplicates = imageURLs.filter { processed.contains($0.path) }
        if duplicates.isEmpty {
            state.uniqueURLs = imageURLs.uniqued()
        } else {
            state.addSheet(type: .duplicateImageSheet)
            let uniques = imageURLs.filter { !duplicates.contains($0) }.uniqued()
            if uniques.isEmpty {
                state.uniqueURLs = nil
            } else {
                state.uniqueURLs = uniques
            }
        }
    }

    // Check if a given file URL refers to a folder
    private func isFolder(_ url: URL) -> Bool {
        let resources = try? url.resourceValues(forKeys: [.isDirectoryKey])
        return resources?.isDirectory ?? false
    }

    // Recursivly iterate over a folder looking for files.
    // Returns an array of contained urls
    private func urlsIn(folder url: URL) -> [URL] {
        var foundURLs = [URL]()
        let fileManager = FileManager.default
        guard let urlEnumerator =
            fileManager.enumerator(at: url,
                                   includingPropertiesForKeys: [.isDirectoryKey],
                                   options: [.skipsHiddenFiles],
                                   errorHandler: nil) else {
                logger.error("\(#function, privacy: .public): No enumerator for \(url, privacy: .public)")
                return []
            }
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            if !isFolder(fileUrl) {
                foundURLs.append(fileUrl)
            }
        }
        return foundURLs
    }
}

// remove duplicates from a sequence while maintaining order

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
