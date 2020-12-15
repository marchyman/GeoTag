//
//  TableController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/24/14.
//  Copyright 2014-2020 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AppKit
import MapKit

final class TableViewController: NSViewController {

    @IBOutlet var appDelegate: AppDelegate!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var imageWell: NSImageView!
    @IBOutlet var mapViewController: MapViewController!

    /// Images in the table
    var images = [ImageData]()

    /// Set of image URLs for duplicate detection
    var imageUrls = Set<URL>()

    // state variables
    var lastSelectedRow: Int?
    var saveInProgress = false

    // MARK: startup

    // object initialization
    override
    func awakeFromNib() {
        // can't make clickDelegate an @IBOutlet; wire it up here
        // mapViewController is a delegate to handle pin drag location changes
        // mapViewController.mapview is a delegate to handle map clicks
        mapViewController.clickDelegate = self
        mapViewController.mapView.clickDelegate = self
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
        tableView.draggingDestinationFeedbackStyle = .none
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(coordFormatChanged),
                       name: Notification.Name("CoordFormatChanged"), object: nil)
    }

    // MARK: populating the table

    /// add the image urls to the table view
    /// - Parameter urls: an array of urls to add to the table
    /// - Returns: true if any duplicate URLs were detected
    ///
    /// The URL is added to a set of URLs and an ImageData instance for the
    /// URL is added to an array of images.  Duplicate URLs are **not** added.
    /// A progress indicator is displayed while the operation is in progress.

    func addImages(urls: [URL]) -> Bool {
        appDelegate.progressIndicator.startAnimation(self)
        var reloadNeeded = false
        var duplicateFound = false
        // silently ignore xmp sidecar files
        let updateGroup = DispatchGroup()
        for url in urls where url.pathExtension.lowercased() != "xmp" {
            if imageUrls.contains(url) {
                duplicateFound = true
            } else {
                imageUrls.insert(url)
                updateGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let imageData = try ImageData(url: url)
                        DispatchQueue.main.async {
                            self.images.append(imageData)
                            reloadNeeded = true
                            updateGroup.leave()
                        }
                    } catch let error as NSError {
                        DispatchQueue.main.async {
                            let desc = NSLocalizedString("WARN_DESC_2",
                                                         comment: "cant process file error")
                                        + "\(url.path)\n\nReason: "
                            unexpected(error: error, desc)
                            updateGroup.leave()
                        }
                    }
                }
            }
        }
        updateGroup.notify(queue: DispatchQueue.main) {
            if reloadNeeded {
                self.reloadAllRows()
            }
            self.appDelegate.progressIndicator.stopAnimation(self)
        }
        return duplicateFound
    }
    
    /// Force a reload of the entire table when the coordinate format changes
    @objc
    private
    func coordFormatChanged() {
        self.reloadAllRows()
    }

    /// save updated geolocation and/or date/time information
    /// - Parameter completion: closure invoked on main thread when save
    /// is complete.
    ///
    /// Each ImageData instance in the table is to save itself. A progress
    /// indicator is displayed while the operation is in progress.

    func saveAllImages(completion: @escaping (Int32)->()) {
        saveInProgress = true
        appDelegate.progressIndicator.startAnimation(self)
        // copy image array so updates during save don't cause issues
        let images = self.images
        var savedResult = Int32(0)
        let updateGroup = DispatchGroup()
        for image in images {
            updateGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let result = image.saveImageFile()
                if result != 0 {
                    savedResult = result
//                    DispatchQueue.main.async {
//                        print("Error updating \(image.url.path)")
//                    }
                }
                updateGroup.leave()
            }
        }
        updateGroup.notify(queue: DispatchQueue.main) {
            self.appDelegate.progressIndicator.stopAnimation(self)
            self.saveInProgress = false
            completion(savedResult)
            self.reloadAllRows()
        }
    }

    // MARK: Image location and date/time changes

    /// Update the date/time taken for an image
    ///
    /// - Parameter row: the row of the table referencing the image to update.
    ///   Row is assumed to be valid.
    /// - Parameter dateValue: the updated date/time value
    /// - Parameter modified: appDeligate modified flag used to propagate
    ///   proper window modified status when using undo/redo.  Always true when
    ///   called from outside this function.
    ///
    /// This function updates the model with undo/redo support and reloads the
    /// table row to show the updated data.

    @objc
    func update(row: Int,
                dateValue: Date,
                modified: Bool = true) {
        // the image to update
        let image = images[row]

        // The existing image date/time for undo
        var oldDateValue = Date()
        if let dateValue = image.dateValue {
            oldDateValue = dateValue
        }

        // current window.modified flag
        let windowModified = appDelegate.modified

        // register the undo information
        let undo = appDelegate.undoManager
        undo.registerUndo(withTarget: self) {
            targetSelf in
            targetSelf.update(row: row,
                              dateValue: oldDateValue,
                              modified: windowModified)
        }

        // update the image
        image.dateValue = dateValue

        // reload the user interface for the row modified and mark the
        // the window as dirty.
        reload(row: row)
        appDelegate.modified = modified
    }

    /// Update the location where an image was taken.
    ///
    /// - Parameter row: the row of the table referencing the image to update
    /// - Parameter validLocation: true if the latitude and longitude are valid
    /// - Parameter coord: latitude/longitude coordinates of the location to be
    ///   assigned to the image.
    /// - Parameter modified: appDeligate modified flag used to propagate
    ///   proper window modified status when using undo/redo.  Always true when
    ///   called from outside this function.
    ///
    /// This function updates the model with undo/redo support and reloads the
    /// table row to show the updated data.
    ///
    /// Note: The system can not handle optional types when used with
    /// registerUndo. The validLocation Boolean is used to mitigate this issue.

    @objc
    func update(row: Int,
                validLocation: Bool,
                coord: Coord,
                modified: Bool = true) {
        let image = images[row]

        // the existing image location for undo
        var oldValidLocation = false
        var oldCoord = Coord()
        if let location = image.location {
            oldValidLocation = true
            oldCoord = location
        }

        // current window.modified flag
        let windowModified = appDelegate.modified

        // register the undo information
        let undo = appDelegate.undoManager
        undo.registerUndo(withTarget: self) {
            targetSelf in
            targetSelf.update(row: row,
                              validLocation: oldValidLocation,
                              coord: oldCoord,
                              modified: windowModified)
        }

        // Update the model and pin location on the map
        if validLocation {
            image.location = coord
            mapViewController.pinMapAt(coords: coord)
        } else {
            image.location = nil
            mapViewController.removeMapPin()
        }

        // reload the user interface for the row modified and mark the
        // the window as dirty.
        reload(row: row)
        appDelegate.modified = modified
    }

    // MARK: menu/click actions

    /// determine if the interpolation menu item should be enabled
    ///
    /// - Returns: true if the item should be enabled
    ///
    /// The interpolation item requires at least three item in the table to
    /// be selected and exactly two of the items to have a location currently
    /// assigned.   Validate those requirements here

    func validateForInterpolation() -> Bool {
        if tableView.numberOfSelectedRows > 2 {
            let filteredRows = tableView.selectedRowIndexes.filter {
                self.images[$0].location != nil
            }
            if filteredRows.count == 2 {
                return true
            }
        }
        return false
    }

    // only enable various tableview related menu items when it makes sense

    @objc
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else { return false }
        switch action {
        case #selector(selectAll(_:)):
            // OK as long as there is at least one entry in the table
            return images.count > 0
        case #selector(clear(_:)):
            // OK if the table is populated and no changes pending
            return images.count > 0 && !appDelegate.modified
        case #selector(discard(_:)):
            // OK if there are changes pending
            return !saveInProgress && appDelegate.modified
        case #selector(discardTracks(_:)):
            // OK if tracks exist
            return !mapViewController.mapLines.isEmpty
        case #selector(cut(_:)),
             #selector(copy(_:)):
            // OK if only one row with a valid location selected
            if !saveInProgress && tableView.numberOfSelectedRows == 1 {
                let image = images[tableView.selectedRow]
                if image.location != nil {
                    return true
                }
            }
        case #selector(paste(_:)):
            // OK if there is at least one selected row and something that
            // looks like a lat and lon in the pasteboard.
            if !saveInProgress && tableView.numberOfSelectedRows > 0 {
                let pb = NSPasteboard.general
                if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string) {
                    // pasteVal should look like "lat lon"
                    let values = pasteVal.components(separatedBy: " ")
                    if values.count == 2 {
                        return true
                    }
                }
            }
        case #selector(delete(_:)):
            // OK if at least one row selected
            return !saveInProgress && tableView.numberOfSelectedRows > 0
        case #selector(showInFinder(_:)):
            // OK if at one row selected
            return !saveInProgress && tableView.numberOfSelectedRows == 1
        case #selector(interpolate(_:)):
            return !saveInProgress && validateForInterpolation()
        case #selector(locnFromTrack(_:)):
            // OK if at least one row selected AND a track log exists
            return !saveInProgress &&
                   !Gpx.gpxTracks.isEmpty &&
                   tableView.numberOfSelectedRows > 0 &&
                   images[tableView.selectedRow].validImage
        case #selector(modifyDateTime(_:)):
            return !saveInProgress &&
                   tableView.numberOfSelectedRows > 0 &&
                   images[tableView.selectedRow].validImage
        case #selector(modifyLocation(_:)):
            return !saveInProgress &&
                tableView.numberOfSelectedRows > 0 &&
                images[tableView.selectedRow].validImage
        default:
            print("#function \(item) not handled")
        }
        return false
    }

    /// discard location changes to the selected item
    ///
    /// - Parameter AnyObject: unused
    ///
    /// Revert any geolocation changes made to all items in the table

    @IBAction
    func discard(_: AnyObject) {
        for image in images {
            image.revert()
        }
        appDelegate.modified = false
        reloadAllRows()
    }

    @IBAction func discardTracks(_ sender: Any) {
        mapViewController.removeTracks()
    }

    /// copy the selected item location into the pasteboard then delete from item
    ///
    /// - Parameter obj: unused in this function
    ///
    /// cut is implemented as a copy followed by a delete.  The obj parameter
    /// is forwarded to copy and delete.

    @IBAction
    func cut(_ obj: AnyObject) {
        copy(obj)
        delete(obj)
        appDelegate.undoManager.setActionName("cut")
    }

    /// copy the selected item location into the pasteboard
    ///
    /// - Parameter AnyObject: unused
    ///
    /// convert the location of the item in the selected row to its
    /// string representation and provide the string to the pasteboard.

    @IBAction
    func copy(_: AnyObject) {
        let row = tableView.selectedRow
        let pb = NSPasteboard.general
        pb.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
        pb.setString(images[row].stringRepresentation,
                     forType: NSPasteboard.PasteboardType.string)
    }

    /// paste item location from the pasteboard to all selected items
    ///
    /// - Parameter AnyObject: unused
    ///
    /// get the string representation of a location from the pasteboard
    /// and convert it to a latitude and longitude.  Apply the location
    /// to all selected items in the table.

    @IBAction
    func paste(_: AnyObject) {
        let pb = NSPasteboard.general
        if let pasteVal = pb.string(forType: NSPasteboard.PasteboardType.string) {
            // pasteVal should look like "lat lon"
            let values = pasteVal.components(separatedBy: " ")
            if values.count == 2 {
                let latitude = values[0].doubleValue
                let longitude = values[1].doubleValue
                _ = updateSelectedRows(coord: Coord(latitude: latitude, longitude: longitude))
                appDelegate.undoManager.setActionName("paste")
            }
        }
    }

    /// remove item location from all selected items
    ///
    /// - Parameter AnyObject: unused
    ///
    /// remove geolocation information from the selected items.

    @IBAction
    func delete(_: AnyObject) {
        appDelegate.undoManager.beginUndoGrouping()
        tableView.selectedRowIndexes.forEach {
            self.update(row: $0,
                        validLocation: false,
                        coord: Coord())
        }
        appDelegate.undoManager.endUndoGrouping()
        appDelegate.undoManager.setActionName("delete")
    }

    @IBAction
    func showInFinder(_: AnyObject) {
        if let row = tableView.selectedRowIndexes.first {
            let url = images[row].url
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    /// remove all items from the table
    ///
    /// - Parameter AnyObject: unused

    @IBAction
    func clear(_: AnyObject) {
        if !appDelegate.modified {
            images = []
            imageUrls.removeAll()
            reloadAllRows()
        }
    }

    /// interpolate locations between two points
    ///
    /// - Parameter AnyObject: unused
    ///
    /// Given: multiple items selected but only two with location information.
    /// Calculate the distance and bearing between the endpoints.  Calculate an
    /// average speed in meters/second between endpoints.  Use the time between
    /// the start point and a point to be interpolated to calulate an estimated
    /// distance.   Calculate an estimated location for the point to be
    /// interpolated using the start point, bearing, and estimated distance.

    @IBAction
    func interpolate(_: AnyObject) {
        struct LocnInfo {
            let lat: Double
            let lon: Double
            let timestamp: TimeInterval
        }
        var startInfo: LocnInfo!
        var endInfo: LocnInfo!
        let rows = tableView.selectedRowIndexes

        // figure out our starting and ending points

        rows.forEach {
            let image = self.images[$0]
            if let coord = image.location {
                let info = LocnInfo(lat: coord.latitude,
                                    lon: coord.longitude,
                                    timestamp: image.dateFromEpoch)
                if startInfo == nil {
                    startInfo = info
                } else if startInfo.timestamp > info.timestamp {
                    endInfo = startInfo
                    startInfo = info
                } else {
                    endInfo = info
                }
            }
        }

        // if start and end have the same timestamp don't bother

        if startInfo == nil || endInfo == nil ||
           startInfo.timestamp == endInfo.timestamp {
           return
        }

        // calculate number of seconds between the two points

        let travelTime = endInfo.timestamp - startInfo.timestamp

        // calculate the distance, bearing, and speed between the two points

        let (distance, bearing) =
            distanceAndBearing(lat1: startInfo.lat, lon1: startInfo.lon,
                               lat2: endInfo.lat, lon2: endInfo.lon)

        // enumerate over the rows again, calculating the approx position
        // using the start point, bearing, and estimated distance

        if distance > 0 {
            let speed = distance / travelTime
            appDelegate.undoManager.beginUndoGrouping()
            rows.forEach {
                let image = self.images[$0]
                let deltaTime = image.dateFromEpoch - startInfo.timestamp
                if deltaTime > 0 && deltaTime < travelTime && image.location == nil {
                    let deltaDist = deltaTime * speed
                    let coord = destFromStart(lat: startInfo.lat,
                                              lon: startInfo.lon,
                                              distance: deltaDist,
                                              bearing: bearing)
                    self.update(row: $0, validLocation: true, coord: coord)
                }
            }
            appDelegate.undoManager.endUndoGrouping()
            appDelegate.undoManager.setActionName("interpolate locations")
        }
    }

    /// Update selected images from data in loaded track logs
    ///
    /// Selected images are updated in parallel.

    @IBAction
    func locnFromTrack(_ sender: Any) {
        let rows = tableView.selectedRowIndexes

        appDelegate.undoManager.beginUndoGrouping()
        let updateGroup = DispatchGroup()
        rows.forEach {
            row in
            let image = self.images[row]
            if image.validImage {
                DispatchQueue.global(qos: .userInitiated).async {
                    updateGroup.enter()
                    Gpx.gpxTracks.forEach {
                        $0.search(image: image) {
                            (coords: Coord) in
                            DispatchQueue.main.async {
                                self.update(row: row,
                                            validLocation: true,
                                            coord: coords)
                            }
                        }
                    }
                    updateGroup.leave()
                }
            }
        }
        updateGroup.notify(queue: DispatchQueue.main) {
            self.appDelegate.undoManager.endUndoGrouping()
            self.appDelegate.undoManager.setActionName("locn from track")
        }
    }

    /// Modify Date/Time menu item action
    ///
    /// - Parameter Any: unused
    ///
    /// Modify the Date Time of selected images.   Open a window to get the time
    /// change for the most selected items.   Calculate the time delta between
    /// the new and the existing value.  Apply the delta to all selected items.
    @IBAction
    func modifyDateTime(_: Any) {
        let row = tableView.selectedRow
        let rows = tableView.selectedRowIndexes
        let image = images[row]
        if image.validImage {
            openChangeTimeWindow(for: image) {
                dateValue in
                let delta = dateValue.timeIntervalSince1970 - image.dateFromEpoch
                self.appDelegate.undoManager.beginUndoGrouping()
                rows.forEach {
                    let img = self.images[$0]
                    if img.validImage,
                       let date = img.dateValue {
                        let newDateValue = Date(timeInterval: delta,
                                                since: date)
                        self.update(row: $0, dateValue: newDateValue)
                    }
                }
                self.appDelegate.undoManager.endUndoGrouping()
                self.appDelegate.undoManager.setActionName("modify date/time")
            }
        }
    }
    
    /// Modify Location menu item action
    ///
    /// - Parameter Any: unused
    ///
    /// Modify the Date Time of selected images.   Open a window to get the time
    /// change for the most selected items.   Calculate the time delta between
    /// the new and the existing value.  Apply the delta to all selected items.
    @IBAction
    func modifyLocation(_: Any) {
        let row = tableView.selectedRow
        let rows = tableView.selectedRowIndexes
        let image = images[row]
        if image.validImage {
            openChangeLocationWindow(for: image) {
                coord in
                self.appDelegate.undoManager.beginUndoGrouping()
                rows.forEach {
                    let img = self.images[$0]
                    if img.validImage {
                        self.update(row: $0,
                                    validLocation: true,
                                    coord: coord)
                    }
                }
                self.appDelegate.undoManager.endUndoGrouping()
                self.appDelegate.undoManager.setActionName("modify location")
            }
        }
    }


    /// open the change date/time window or the change location window
    /// double click in the date/time column to change the timestamp
    /// double click in the latitude or longitude columns to change location
    @IBAction
    func doubleClick(_ sender: NSTableView) {
        let row = sender.clickedRow
        if row >= 0 && row < images.count {
            let column = sender.clickedColumn
            if column >= 0 {
                let image = images[row]
                if image.validImage {
                    let tableColumn = sender.tableColumns[column]
                    let id = tableColumn.identifier
                    switch id {
                    case NSUserInterfaceItemIdentifier("dateTime"):
                        openChangeTimeWindow(for: image) {
                            dateValue in
                            self.update(row: row, dateValue: dateValue)
                        }
                    case NSUserInterfaceItemIdentifier("latitude"),
                         NSUserInterfaceItemIdentifier("longitude"):
                        openChangeLocationWindow(for: image) {
                            coord in
                            self.update(row: row,
                                        validLocation: true,
                                        coord: coord)
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
    }

    //MARK: Functions to reload/update table rows

    /// Reload the table
    ///
    /// Clear the image well and remove any markers from the map view.
    /// Reloading all rows also clears undo actions.

    func reloadAllRows() {
        appDelegate.undoManager.removeAllActions()
        let sortedImages = NSMutableArray(array: images)
        sortedImages.sort(using: tableView.sortDescriptors)
        images = sortedImages as! [ImageData]
        tableView.reloadData()
        imageWell.image = nil
        mapViewController.removeMapPin()
    }

    /// Reload the date/time and location for a specific row.
    ///
    /// - Parameter row: the row to be refreshed.
    ///
    /// Update the date/time, latitude and longitude columns for the given row.

    func reload(row: Int) {
        let dateTimeColumn = tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("dateTime"))
        let cols = IndexSet(integersIn: dateTimeColumn..<dateTimeColumn+3)
        tableView.reloadData(forRowIndexes: IndexSet(integer: row),
                             columnIndexes: cols)
    }

    /// Update all selected rows with the given latitude and longitude
    ///
    /// - Parameter latitude: the new latitude for the selected items
    /// - Parameter longitude: the new longitude for the selected items
    ///
    /// Update all selected rows as a single undo group.

    func updateSelectedRows(coord: Coord) -> Bool {
        let rows = tableView.selectedRowIndexes
        guard !rows.isEmpty else { return false }
        appDelegate.undoManager.beginUndoGrouping()
        tableView.selectedRowIndexes.forEach {
            self.update(row: $0, validLocation: true, coord: coord)
        }
        appDelegate.undoManager.endUndoGrouping()
        return true
    }
}


// MARK: TableView delegate functions

extension TableViewController: NSTableViewDelegate {

    // return view for requested column.
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        let image = images[row]
        var value = ""
        var tip: String? = nil
        if let id = tableColumn?.identifier {
            switch id {
            case NSUserInterfaceItemIdentifier("imageName"):
                value = image.imageName
                if image.sandboxXmp != nil {
                    value += "*"
                }
                tip = image.url.path
            case NSUserInterfaceItemIdentifier("dateTime"):
                value = image.dateTime
            case NSUserInterfaceItemIdentifier("latitude"):
                if let coord = image.location {
                    switch Preferences.coordFormat() {
                    case .deg:
                        value = String(format: "% 2.6f", coord.latitude)
                    case .degMin:
                        value = coord.dm.latitude
                    case .degMinSec:
                        value = coord.dms.latitude
                    }
                }
            case NSUserInterfaceItemIdentifier("longitude"):
                if let coord = image.location {
                    switch Preferences.coordFormat() {
                    case .deg:
                        value = String(format: "% 2.6f", coord.longitude)
                    case .degMin:
                        value = coord.dm.longitude
                    case .degMinSec:
                        value = coord.dms.longitude
                    }
                }
            default:
                break
            }
            let colView =
                tableView.makeView(withIdentifier: id, owner: nil) as! NSTableCellView
            colView.textField?.stringValue = value;
            if row == tableView.selectedRow {
                lastSelectedRow = row
                colView.textField?.textColor = NSColor.yellow
            } else {
                lastSelectedRow = nil
                colView.textField?.textColor = nil
            }
            if let tooltip = tip {
                colView.textField?.toolTip = tooltip
            }
            if !image.validImage {
                colView.textField?.textColor = NSColor.gray
            } else if image.backupFailed {
                colView.textField?.textColor = NSColor.systemOrange
            } else if image.updateFailed {
                colView.textField?.textColor = NSColor.systemRed
            }
            return colView
        }
        return nil
    }

    // don't allow rows with non images to be selected while still allowing
    // drags and ranges.
    func tableView(_ tableView: NSTableView,
                   selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        var selectionIndexes = IndexSet()
        proposedSelectionIndexes.forEach {
            if self.images[$0].validImage {
               selectionIndexes.insert($0)
            }
        }
        return selectionIndexes
    }

    /// match the image to the selected row
    func tableViewSelectionDidChange(_ notification: Notification) {

        // redraw last selected row in normal colors

        if let lastSelectedRow = self.lastSelectedRow {
            reload(row: lastSelectedRow)
        }
        let row = tableView.selectedRow
        if row < 0 {
            imageWell.image = nil
            mapViewController.removeMapPin()
        } else {
            let image = images[row]
            imageWell.image = image.image
            if let coord = image.location {
                reload(row: row) // change color of selected row
                mapViewController.pinMapAt(coords: coord)
            } else {
                mapViewController.removeMapPin()
            }
        }
    }
}

// MARK: TableView data source functions

extension TableViewController: NSTableViewDataSource {

    /// table size is one row per image in the images array
    func numberOfRows(in tableView: NSTableView) -> Int {
        return images.count
    }

    // table sorting by column contents
    func tableView(_ tableView: NSTableView,
                   sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        reloadAllRows()
    }

    // validate a proposed drop
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let pb = info.draggingPasteboard
        if let paths = pb.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            let fileManager = FileManager.default
            for path in paths {
                if !fileManager.fileExists(atPath: path) ||
                   imageUrls.contains(URL(fileURLWithPath: path)) {
                    return []
                }
            }
            return .link
        }
        return []
    }

    // Add dropped files to the table
    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        let pb = info.draggingPasteboard
        if let paths = pb.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            var urls = [URL]()
            for path in paths {
                let fileURL = URL(fileURLWithPath: path)
                if !appDelegate.addUrlsInFolder(url: fileURL, toUrls: &urls) {
                    if !appDelegate.isGpxFile(fileURL) {
                        urls.append(fileURL)
                    }
                }
            }
            return !addImages(urls: urls)
        }
        return false
    }
}

extension TableViewController: MapViewDelegate {

    /// update the location for selected rows UNLESS a save is in progress.
    /// Location updates are not allowed during a save.
    func mouseClicked(mapView: MapView!,
                      location: CLLocationCoordinate2D) {
        if !saveInProgress {
            _ = updateSelectedRows(coord: location)
            appDelegate.undoManager.setActionName("location change")
        }
    }
}

//MARK: TableView extenstion for right click

/// in a table a right click will bring up a context menu.  I prefer that
/// the menu pertain to the row that was clicked. Do that by selecting the
/// row the mouse is on assuming the row is populated.  Once the row is
/// selected send the event to the super class for processing.  This is done
/// in a TableView extension.

extension NSTableView {
    open override
    func rightMouseDown(with theEvent: NSEvent) {
        let localPoint = convert(theEvent.locationInWindow, from: nil)
        let row = self.row(at: localPoint)
        if row >= 0 {
            if !isRowSelected(row) {
                selectRowIndexes(IndexSet(integer: row),
                                 byExtendingSelection: false)
            }
        } else {
            deselectAll(self)
        }
        super.rightMouseDown(with: theEvent)
    }
}

//MARK: String extension -> Double

/// Convert a string to a double through a cast to NSString.
/// Used in paste code to handle lat and lon as a string value.

extension String {
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
}
