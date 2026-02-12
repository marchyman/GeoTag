import AppKit
import Foundation
import GpxTrackLog
import ImageData

// events that trigger a change of state

enum GeoTagEvent: Equatable {
    case addImage(ImageData)
    case backupFolderSizeCheck
    case backupURLChanged(URL?)
    case badGpxFile(String)
    case catchUnexpectedError(String?, String?)
    case changeTimeZone
    case discardRequest
    case finishedAddingTracks
    case goodGpxFile(String)
    case gpxLoadViewClosed
    case initBackupURL
    case initialBackupNotice
    case mainWindowChange(NSWindow?)
    case openCommand
    case openFiles([URL])
    case quitRequested
    case readTrackLog(String, GpxTrackLog?)
    case removeOldFiles
    case searchForChanged(String)
    case searchForCleared
    case selectionChanged(Set<ImageData.ID>)
    case sheetDismissed
    case showInFinder
    case sortOrderChanged([KeyPathComparator<ImageData>])
    case sortUsingCurrentComparator
    case terminateRequest
    case timeZoneChanged(TimeZone)
    case toggleLogWindow
}

// A description for each event

extension GeoTagEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .addImage: "addImage"
        case .backupFolderSizeCheck: "backupFolderSizeCheck"
        case .backupURLChanged: "backupURLChanged"
        case .badGpxFile: "badGpxFile"
        case .catchUnexpectedError: "catchUnexpectedError"
        case .changeTimeZone: "changeTimeZone"
        case .discardRequest: "discardRequest"
        case .finishedAddingTracks: "finishedAddingTracks"
        case .goodGpxFile: "goodGpxFile"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .initBackupURL: "initBackupURL"
        case .initialBackupNotice: "initialBackupCheck"
        case .mainWindowChange: "mainWindowChange"
        case .openCommand: "openCommand"
        case .openFiles: "openFiles"
        case .quitRequested: "quitRequested"
        case .readTrackLog: "readTrackLog"
        case .removeOldFiles: "removeOldFiles"
        case .searchForChanged: "searchForChanged"
        case .searchForCleared: "clearSearchCleared"
        case .selectionChanged: "selectionChanged"
        case .sheetDismissed: "sheetDismissed"
        case .showInFinder: "showInFinder"
        case .sortOrderChanged: "sortOrderChanged"
        case .sortUsingCurrentComparator: "sortUsingCurrentComparator"
        case .terminateRequest: "terminateRequest"
        case .timeZoneChanged: "timeZoneChanged"
        case .toggleLogWindow: "toggleLogWindow"
        }
    }
}
