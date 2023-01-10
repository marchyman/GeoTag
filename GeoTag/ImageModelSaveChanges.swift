//
//  ImageModelSaveChanges.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/9/23.
//

import Foundation

extension ImageModel {

    func saveChanges(timeZone: TimeZone?) async throws {
        try makeBackupFile()
        try await Exiftool.helper.update(from: self, timeZone: timeZone)
    }

    func makeBackupFile() throws {
        // check if backups are desired
        // backup the file
    }
}
