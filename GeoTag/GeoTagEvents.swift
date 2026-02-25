import AppKit
import Coords
import Foundation
import GpxTrackLog
import ImageData
import SwiftUI

// events that trigger a change of state

enum GeoTagEvent: Equatable {
    case addImage(ImageData)
    case addressChanged(Set<ImageData.ID>, Place)
    case backupFolderSizeCheck
    case backupURLChanged(URL?)
    case badGpxFile(String)
    case catchUnexpectedError(String?, String?)
    case changeTimeZone
    case clearPlaces
    case findInMap(Bool)
    case finishedAddingTracks
    case goodGpxFile(String)
    case gpxLoadViewClosed
    case initBackupURL
    case initialBackupNotice
    case linkPairedImages
    case locationChanged(Coords)
    case locationFromTrack([LocationHelper.LocationById])
    case mainWindowChange(NSWindow?)
    case newThumbnail(Image)
    case openCommand
    case openFiles([URL])
    case placeSelection(Place)
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
        case .clearPlaces: "clearPlaces"
        case .findInMap: "findInMap"
        case .finishedAddingTracks: "finishedAddingTracks"
        case .goodGpxFile: "goodGpxFile"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .initBackupURL: "initBackupURL"
        case .initialBackupNotice: "initialBackupCheck"
        case .linkPairedImages: "linkPairedImages"
        case .locationChanged: "locationChanged"
        case .locationFromTrack: "locationFromTrack"
        case .mainWindowChange: "mainWindowChange"
        case .newThumbnail: "newThumbnail"
        case .openCommand: "openCommand"
        case .openFiles: "openFiles"
        case .placeSelection: "placeSelection"
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
