//
//  ImageModelSaveChanges.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/9/23.
//

import Foundation

extension ImageModel {

    // make a backup of self into the folder identifed by the given URL
    func makeBackupFile(backupFolder: URL) async throws {
        // ;;;
        // backup the file
    }

    func saveChanges(timeZone: TimeZone?) async throws {
        try await Exiftool.helper.update(from: self, timeZone: timeZone)
    }

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
        var url = fileURL as NSURL
        try url.setResourceValue(tagValues, forKey: .tagNamesKey)
    }
}
