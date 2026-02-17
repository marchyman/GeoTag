import AppKit
import Coords
import Foundation
import GpxTrackLog
import ImageData

// events that trigger a change of state

enum GeoTagEvent: Equatable {
    case addImage(ImageData)
    case addressChanged(Set<ImageData.ID>, FullAddress)
    case backupFolderSizeCheck
    case backupURLChanged(URL?)
    case badGpxFile(String)
    case catchUnexpectedError(String?, String?)
    case changeTimeZone
    case finishedAddingTracks
    case goodGpxFile(String)
    case gpxLoadViewClosed
    case initBackupURL
    case initialBackupNotice
    case linkPairedImages
    case locationChanged(Coords)
    case mainWindowChange(NSWindow?)
    case openCommand
    case openFiles([URL])
    case quitRequested
    case readTrackLog(String, GpxTrackLog?)
    case removeOldFiles
    case searchActiveChanged(Bool)
    case searchTextChanged(String)
    case selectionChanged(Set<ImageData.ID>)
    case sheetDismissed
    case sortOrderChanged([KeyPathComparator<ImageData>])
    case sortUsingCurrentComparator
    case terminateRequest
    case timeZoneChanged(TimeZone)
    case toggleLogWindow
    // pasteboard events
    case cutRequest
    case copyRequest
    case pasteRequest
    case deleteRequest
    case selectAllRequest
    // SaveItems events
    case saveRequest
    case discardChangesRequest
    case discardTracksRequest
    case clearImagesRequest
}

// A description for each event

extension GeoTagEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .addImage: "addImage"
        case .addressChanged: "addressChanged"
        case .backupFolderSizeCheck: "backupFolderSizeCheck"
        case .backupURLChanged: "backupURLChanged"
        case .badGpxFile: "badGpxFile"
        case .catchUnexpectedError: "catchUnexpectedError"
        case .changeTimeZone: "changeTimeZone"
        case .finishedAddingTracks: "finishedAddingTracks"
        case .goodGpxFile: "goodGpxFile"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .initBackupURL: "initBackupURL"
        case .initialBackupNotice: "initialBackupCheck"
        case .linkPairedImages: "linkPairedImages"
        case .locationChanged: "locationChanged"
        case .mainWindowChange: "mainWindowChange"
        case .openCommand: "openCommand"
        case .openFiles: "openFiles"
        case .quitRequested: "quitRequested"
        case .readTrackLog: "readTrackLog"
        case .removeOldFiles: "removeOldFiles"
        case .searchActiveChanged: "searchActiveChanged"
        case .searchTextChanged: "searchTextChanged"
        case .selectionChanged: "selectionChanged"
        case .sheetDismissed: "sheetDismissed"
        case .sortOrderChanged: "sortOrderChanged"
        case .sortUsingCurrentComparator: "sortUsingCurrentComparator"
        case .terminateRequest: "terminateRequest"
        case .timeZoneChanged: "timeZoneChanged"
        case .toggleLogWindow: "toggleLogWindow"

        // pasteboard events
        case .cutRequest: "cutRequest"
        case .copyRequest: "copyRequest"
        case .pasteRequest: "pasteRequest"
        case .deleteRequest: "deleteRequest"
        case .selectAllRequest: "selectAllRequest"

        // SaveItems events
        case .saveRequest: "saveReqest"
        case .discardChangesRequest: "discardChangesRequest"
        case .discardTracksRequest: "discardTracksRequest"
        case .clearImagesRequest: "clearImagesRequest"
        }
    }
}
