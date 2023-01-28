//
//  ContentViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/27/23.
//

import SwiftUI

// An ObservableObject containint items only used by ContentView

final class ContentViewModel: ObservableObject {
    @Published var showingProgressView = false
    @Published var sheetType: SheetType?
    @Published var presentConfirmation = false
    @Published var removeOldFiles = false
    @Published var selectedMenuAction: AppViewModel.MenuAction = .none

    public static let shared = ContentViewModel()

    // Fields used select a sheet to attach to the content view
    // some sheets are associated with errors.  Setting sheetType will
    // trigger display of the sheet
    var sheetStack = [SheetInfo]()
    var sheetError: NSError?
    var sheetMessage: String?
    var saveIssues = [ImageModel.ID : String ]()

    // Confirmation required optional data
    var confirmationMessage: String?
    var confirmationAction: (@MainActor () -> Void)?

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
}
