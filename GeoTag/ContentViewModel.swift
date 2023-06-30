//
//  ContentViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/27/23.
//

import SwiftUI
import Observation

// items used to determing the state of ContentView
// Observable currently requires all items to be initialized.
// Tell swiftlint to be quiet about setting optionals to nil
// swiftlint:disable redundant_optional_initialization

@Observable
final class ContentViewModel {
    public static let shared = ContentViewModel()

    var showingProgressView = false
    var sheetType: SheetType? = nil
    var presentConfirmation = false
    var removeOldFiles = false
    var changeTimeZoneWindow = false

    // Fields used select a sheet to attach to the content view
    // some sheets are associated with errors.  Setting sheetType will
    // trigger display of the sheet
    var sheetStack = [SheetInfo]()
    var sheetError: NSError? = nil
    var sheetMessage: String? = nil
    var saveIssues = [ImageModel.ID: String]()

    // Confirmation required optional data
    var confirmationMessage: String? = nil
    var confirmationAction: (@MainActor () -> Void)? = nil

    // The folder containing backups is scanned at startup and the user
    // is given the option to remove backups older than 7 days.  This info
    // is used in an alert when files that can be deleted are found.

    var oldFiles = [URL]()
    var folderSize = 0
    var deletedSize = 0
}

// Add a sheet to display

extension ContentViewModel {
    struct SheetInfo {
        let sheetType: SheetType
        let sheetError: NSError?
        let sheetMessage: String?
    }

    func addSheet(type: SheetType, error: NSError? = nil, message: String? = nil) {
        if sheetType == nil {
            sheetType = type
            sheetError = error
            sheetMessage = message
        } else {
            // create a SheetInfo and add it to the stack of pending sheets
            sheetStack.append(SheetInfo(sheetType: type,
                                        sheetError: error,
                                        sheetMessage: message))
        }
    }

    // return true if a sheet of the given type is enqueued

    func hasSheet(type: SheetType) -> Bool {
        if sheetType == type {
            return true
        }
        return sheetStack.contains { $0.sheetType == type }
    }

    func addSheetOnce(type: SheetType, error: NSError? = nil, message: String? = nil) {
        if !hasSheet(type: type) {
            addSheet(type: type, error: error, message: message)
        }
    }
}

// swiftlint:enable redundant_optional_initialization
