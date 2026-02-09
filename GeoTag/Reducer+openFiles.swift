import Foundation
import ImageData
import SwiftUI
import UDF

// initiate processing of the given array of URLs. Get the full list
// of unique urls and then process each in a background task.

extension GeoTagReducer {
    func openFiles(_ state: inout GeoTagState, urls: [URL]) {
        // marking app as busy will show progress indicator
        state.applicationBusy.toggle()

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
        let uniques: [URL]
        if duplicates.isEmpty {
            uniques = imageURLs.uniqued()
        } else {
            state.addSheet(type: .duplicateImageSheet)
            uniques = imageURLs.filter { !duplicates.contains($0) }.uniqued()
        }

        Task {
            await images(for: uniques)
            // TODO
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
                logger.error("\(#function): No enumerator for \(url, privacy: .public)")
                return []
            }
        while let fileUrl = urlEnumerator.nextObject() as? URL {
            if !isFolder(fileUrl) {
                foundURLs.append(fileUrl)
            }
        }
        return foundURLs
    }

    // process images in a task group, one task per image, skipping gpx urls
    nonisolated private
    func images(for imageURLs: [URL]) async {
        await withTaskGroup(of: ImageData?.self) { group in
            for url in imageURLs where url.pathExtension.lowercased() != "gpx" {
                group.addTask {
                    do {
                        // create imagedata entry here
                        return nil
                    } catch {
                        await MainActor.run {
                            // store.send(.catchUnexpectedError(
                            //     error.localizedDescription,
                            //     "Failed to open file \(url.path)"))
                        }
                        return nil
                    }
                }
            }
            for await imageData in group.compactMap({$0}) {
                await MainActor.run {
                    // store.send(.addImage(imageData))
                }
            }
        }
    }
}

// remove duplicates from a sequence while maintaining order

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
