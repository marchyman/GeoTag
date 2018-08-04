//
//  TableController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/24/14.
//
// Copyright 2014-2018 Marco S Hyman
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

    var images = [ImageData]()
    var imageUrls = Set<URL>()
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
    }

    //MARK: populating the table

    /// add the url of an image to the table view
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
        for url in urls {
            if imageUrls.contains(url) {
                duplicateFound = true
            } else {
                imageUrls.insert(url)
                images.append(ImageData(url: url))
                reloadNeeded = true
            }
        }
        if reloadNeeded {
            reloadAllRows()
        }
        appDelegate.progressIndicator.stopAnimation(self)
        return duplicateFound
    }

    /// update geolocation information for images in the table
    /// - Parameter completion: closure invoked only if all images were
    ///   successfully saved.  Completion is called on the main thread.
    /// - Returns: true if all modified images were saved, otherwise false
    ///
    /// Each ImageData instance in the table is to save itself. A progress
    /// indicator is displayed while the operation is in progress.

    func saveAllImages(completion: @escaping ()->()) {
        saveInProgress = true
        appDelegate.progressIndicator.startAnimation(self)
        // copy image array so updates during save don't cause issues
        let images = self.images
        let updateGroup = DispatchGroup()
        var allSaved = true
        for image in images {
            DispatchQueue.global(qos: .userInitiated).async {
                updateGroup.enter()
                if !image.saveImageFile() {
                    allSaved = false
                }
                updateGroup.leave()
            }
        }
        updateGroup.notify(queue: DispatchQueue.main) {
            self.appDelegate.progressIndicator.stopAnimation(self)
            ImageData.enableSaveWarnings()
            self.saveInProgress = false
            if allSaved {
                completion()
            }
        }
    }

    //MARK: Image location or timestamp changes

    /// timestamp or location update with undo/redo support.
    ///
    /// - Parameter row: the row of the table referencing the image to update
    /// - Parameter validLocation: true if the latitude and longitude are valid
    /// - Parameter latLon: latitude/longitude of the location to be assigned to
    ///   the image.
    /// - Parameter updateTimestamp: true if the timestamp needs updating
    /// - Parameter timestamp: the date/time of this image
    /// - Parameter modified: appDeligate modified flag used to propagate
    ///   proper modified status when using undo.   Always true when called
    ///   from outside this function.
    ///
    /// update image location for the image at the specified row.  Prepare
    /// an invocation with target self to handle undo and redo.
    ///
    /// Note: The system can not handle optional types when used with
    /// prepareWithInvocationTarget.  A tuple will not work, either.  Both
    /// will cause an EXC_BAD_ACCESS to be generated (true as of Xcode 6 beta 3)
    /// The validLocation Boolean is used to mitigate this issue.

    @objc
    func updateLocation(row: Int,
                        validLocation: Bool,
                        latLon: Coord,
                        updateTimestamp: Bool,
                        timestamp: Date,
                        modified: Bool = true) {
        // the image to update
        let image = images[row]

        // undo information based upon current state
        // current lat/lon
        var oldLatLon = Coord()
        var oldLatLonValid = false
        if image.location != nil {
            oldLatLon = image.location!
            oldLatLonValid = true
        }
        // current date/time
        var oldTimestamp = Date()
        var oldUpdateTimestamp = false
        if let dateTime = image.dateValue {
            oldTimestamp = dateTime
            oldUpdateTimestamp = true
        }
        // current window.modified flag
        let windowModified = appDelegate.modified

        // register the undo information
        let undo = appDelegate.undoManager
        undo.registerUndo(withTarget: self) {
            targetSelf in
            targetSelf.updateLocation(row: row,
                                      validLocation: oldLatLonValid,
                                      latLon: oldLatLon,
                                      updateTimestamp: oldUpdateTimestamp,
                                      timestamp: oldTimestamp,
                                      modified: windowModified)
        }

        // update image location.  If the location is not valid any
        // existing location is removed.
        if validLocation {
            image.setLocation(latLon)
            mapViewController.pinMapAt(coords: latLon)
        } else {
            image.setLocation(nil)
            mapViewController.removeMapPin()
        }

        // update the date/time if requested.  Unlike lat/lon the date/time is
        // only updated when requested.
        if updateTimestamp {
            image.dateValue = timestamp
        }

        // reload the user interface for the row modified and mark the
        // the window as dirty.
        reload(row: row)
        appDelegate.modified = modified
    }

    // MARK: menu actions

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
        case #selector(interpolate(_:)):
            return !saveInProgress && validateForInterpolation()
        case #selector(locnFromTrack(_:)):
            // OK if at least one row selected AND a track log exists
            return !saveInProgress &&
                   !Gpx.gpxTracks.isEmpty &&
                   tableView.numberOfSelectedRows > 0 &&
                   images[tableView.selectedRow].validImage
        default:
            print("default for item \(item)")
        }
        return false
    }

    /// open the change date/time window for an image
    @IBAction
    func doubleClick(_ sender: NSTableView) {
        let row = sender.clickedRow
        if row >= 0 && row < images.count {
            let image = images[row]
            if image.validImage {
                openChangeTimeWindow(for: image) {
                    dateValue in
                    DispatchQueue.main.async {
                        var latLon = Coord()
                        var validLatLon = false
                        if let locn = image.location {
                            latLon = locn
                            validLatLon = true
                        }
                        self.appDelegate.modified = true
                        self.updateLocation(row: row,
                                            validLocation: validLatLon,
                                            latLon: latLon,
                                            updateTimestamp: true,
                                            timestamp: dateValue)

                    }
                }
            }
        }
    }

    /// discard location changes to the selected item
    ///
    /// - Parameter AnyObject: unused
    ///
    /// Revert any geolocation changes made to all items in the table

    @IBAction
    func discard(_: AnyObject) {
        for image in images {
            image.revertLocation()
        }
        appDelegate.modified = false
        reloadAllRows()
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
                updateSelectedRows(latLon: Coord(latitude: latitude, longitude: longitude))
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
            self.updateLocation(row: $0, validLocation: false,
                                latLon: Coord(), updateTimestamp: false,
                                timestamp: Date())
        }
        appDelegate.undoManager.endUndoGrouping()
        appDelegate.undoManager.setActionName("delete")
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
            if let latLon = image.location {
                let info = LocnInfo(lat: latLon.latitude,
                                    lon: latLon.longitude,
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

        // calculate the distance, bearing, and speed between the two points

        let (distance, bearing) =
            distanceAndBearing(lat1: startInfo.lat, lon1: startInfo.lon,
                               lat2: endInfo.lat, lon2: endInfo.lon)

        // enumerate over the rows again, calculating the approx position
        // using the start point, bearing, and estimated distance

        if distance > 0 {
            let speed = distance / (endInfo.timestamp - startInfo.timestamp)
            // print("\(distance) meters \(bearing)º at \(speed) meters/sec")
            appDelegate.undoManager.beginUndoGrouping()
            rows.forEach {
                let image = self.images[$0]
                let deltaTime = image.dateFromEpoch - startInfo.timestamp
                if deltaTime > 0 && deltaTime <= endInfo.timestamp &&
                   image.location == nil {
                    let deltaDist = deltaTime * speed
                    let latLon = destFromStart(lat: startInfo.lat, lon: startInfo.lon,
                                               distance: deltaDist, bearing: bearing)
                    self.updateLocation(row: $0,
                                        validLocation: true,
                                        latLon: latLon,
                                        updateTimestamp: false,
                                        timestamp: Date())
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
                        $0.update(image: image) {
                            (coords: Coord) in
                            DispatchQueue.main.async {
                                self.updateLocation( row: row,
                                                     validLocation: true,
                                                     latLon: coords,
                                                     updateTimestamp: false,
                                                     timestamp: Date())
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

    //MARK: Functions to reload/update table rows

    /// Reload the table
    ///
    /// Clear the image well and remove any markers from the map view.
    /// Reloading all rows also clears undo actions.

    func reloadAllRows() {
        appDelegate.undoManager.removeAllActions()
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

    func updateSelectedRows(latLon: Coord) {
        appDelegate.undoManager.beginUndoGrouping()
        tableView.selectedRowIndexes.forEach {
            self.updateLocation(row: $0,
                                validLocation: true,
                                latLon: latLon,
                                updateTimestamp: false,
                                timestamp: Date())
        }
        appDelegate.undoManager.endUndoGrouping()
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
                value = image.name ?? "Unknown"
                tip = image.url.path
            case NSUserInterfaceItemIdentifier("dateTime"):
                value = image.date
            case NSUserInterfaceItemIdentifier("latitude"):
                if let lat = image.location?.latitude {
                    value = String(format: "% 2.6f", lat)
                }
            case NSUserInterfaceItemIdentifier("longitude"):
                if let lon = image.location?.longitude {
                    value = String(format: "% 2.6f", lon)
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
            if let latLon = image.location {
                reload(row: row) // change color of selected row
                mapViewController.pinMapAt(coords: latLon)
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
        let sortedImages = NSMutableArray(array: images)
        sortedImages.sort(using: tableView.sortDescriptors)
        images = sortedImages as! [ImageData]
        tableView.reloadData()
    }

    // validate a proposed drop
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let pb = info.draggingPasteboard()
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
        let pb = info.draggingPasteboard()
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
            updateSelectedRows(latLon: location)
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
