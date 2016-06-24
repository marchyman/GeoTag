//
//  TableController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/24/14.
//  Copyright (c) 2014-2016 Marco S Hyman, CC-BY-NC
//

import Foundation
import AppKit
import MapKit

final class TableViewController: NSViewController, NSTableViewDelegate,
    NSTableViewDataSource {

    @IBOutlet var appDelegate: AppDelegate!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var imageWell: NSImageView!
//  @IBOutlet var mapView: MapView!

    var images = [ImageData]()
    var imageURLs = Set<NSURL>()
    var lastSelectedRow: Int?

    // MARK: startup

    // object initialization
    override func awakeFromNib() {
        // can't make clickDelegate an @IBOutlet; wire it up here
        // webViewController is a delegate to handle location changes
//        webViewController.clickDelegate = self
        tableView.registerForDraggedTypes([NSFilenamesPboardType]);
        tableView.draggingDestinationFeedbackStyle = .None
    }

    //MARK: populating the table

    /// add the url of an image to the table view
    /// - Parameter urls: an array of urls to add to the table
    /// - Returns: true if any duplicate URLs were detected
    ///
    /// The URL is added to a set of URLs and an ImageData instance for the
    /// URL is added to an array of images.  Duplicate URLs are **not** added.
    /// A progress indicator is displayed while the operation is in progress.

    func addImages(urls: [NSURL]) -> Bool {
        appDelegate.progressIndicator.startAnimation(self)
        var reloadNeeded = false
        var duplicateFound = false
        for url in urls {
            if imageURLs.contains(url) {
                duplicateFound = true
            } else {
                imageURLs.insert(url)
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
    ///
    /// Each ImageData instance in the table is to save itself. A progress
    /// indicator is displayed while the operation is in progress.

    func saveAllImages() {
        appDelegate.progressIndicator.startAnimation(self)
        for image in images {
            image.saveImageFile()
        }
        appDelegate.progressIndicator.stopAnimation(self)
    }

    //MARK: Image location change handling

    /// location update with undo/redo support.
    ///
    /// - Parameter row: the row of the table referencing the image to update
    /// - Parameter validLocation: true if the latitude and longitude are valid
    /// - Parameter latitude: latitude of the location to be assigned to
    ///   the image.
    /// - Parameter longitude: longitude of the location to be assigned to
    ///   the image
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

    func updateLocationAtRow(row: Int, validLocation: Bool, latitude: Double,
                             longitude: Double, modified: Bool = true) {
        var oldValidLocation: Bool
        var oldLatitude: Double
        var oldLongitude: Double
        let image = images[row]
        if image.latitude != nil && image.longitude != nil {
            oldValidLocation = true
            oldLatitude = image.latitude!
            oldLongitude = image.longitude!
        } else {
            oldValidLocation = false
            oldLatitude = 0
            oldLongitude = 0
        }
        let undo = appDelegate.undoManager
        undo.prepareWithInvocationTarget(self).updateLocationAtRow(row,
            validLocation: oldValidLocation, latitude: oldLatitude,
            longitude: oldLongitude, modified: appDelegate.modified)
        if validLocation {
            image.setLatitude(latitude, longitude: longitude)
//            webViewController.pinMapAtLatitude(image.latitude!,
//                                               longitude: image.longitude!)
        } else {
            image.setLatitude(nil, longitude: nil)
//            webViewController.removeMapPin()
        }
        reloadRow(row)
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
            let rows = tableView.selectedRowIndexes
            var count = 0
            rows.enumerateIndexesUsingBlock {
                (row, _) -> Void in
                if self.images[row].latitude != nil &&
                   self.images[row].longitude != nil {
                   count += 1
                }
            }
            if count == 2 {
                return true
            }
        }
        return false
    }

    // only enable various tableview related menu items when it makes sense

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(selectAll(_:)):
            // OK as long as there is at least one entry in the table
            return images.count > 0
        case #selector(clear(_:)):
            // OK if the table is populated and no changes pending
            return images.count > 0 && !appDelegate.modified
        case #selector(discard(_:)):
            // OK if there are changes pending
            return appDelegate.modified
        case #selector(cut(_:)),
             #selector(copy(_:)):
            // OK if only one row with a valid location selected
            if tableView.numberOfSelectedRows == 1 {
                let image = images[tableView.selectedRow]
                if (image.latitude != nil && image.longitude != nil ) {
                    return true
                }
            }
        case #selector(paste(_:)):
            // OK if there is at least one selected row and something that
            // looks like a lat and lon in the pasteboard.
            if tableView.numberOfSelectedRows > 0 {
                let pb = NSPasteboard.generalPasteboard()
                if let pasteVal = pb.stringForType(NSPasteboardTypeString) {
                    // pasteVal should look like "lat lon"
                    let values = pasteVal.componentsSeparatedByString(" ")
                    if values.count == 2 {
                        return true
                    }
                }
            }
        case #selector(delete(_:)):
            // OK if at least one row selected
            return tableView.numberOfSelectedRows > 0
        case #selector(interpolate(_:)):
            return validateForInterpolation()
        default:
            print("default for item \(menuItem)")
        }
        return false
    }

    /// discard location changes to the selected item
    ///
    /// - Parameter AnyObject: unused
    ///
    /// Revert any geolocation changes made to all items in the table

    @IBAction func discard(_: AnyObject) {
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

    @IBAction func cut(obj: AnyObject) {
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

    @IBAction func copy(_: AnyObject) {
        let row = tableView.selectedRow
        let pb = NSPasteboard.generalPasteboard()
        pb.declareTypes([NSPasteboardTypeString], owner: self)
        pb.setString(images[row].stringRepresentation,
                     forType: NSPasteboardTypeString)
    }

    /// paste item location from the pasteboard to all selected items
    ///
    /// - Parameter AnyObject: unused
    ///
    /// get the string representation of a location from the pasteboard
    /// and convert it to a latitude and longitude.  Apply the location
    /// to all selected items in the table.

    @IBAction func paste(_: AnyObject) {
        let pb = NSPasteboard.generalPasteboard()
        if let pasteVal = pb.stringForType(NSPasteboardTypeString) {
            // pasteVal should look like "lat lon"
            let values = pasteVal.componentsSeparatedByString(" ")
            if values.count == 2 {
                let latitude = values[0].doubleValue
                let longitude = values[1].doubleValue
                updateSelectedRows(latitude: latitude, longitude: longitude)
                appDelegate.undoManager.setActionName("paste")
            }
        }
    }

    /// remove item location from all selected items
    ///
    /// - Parameter AnyObject: unused
    ///
    /// remove geolocation information from the selected items.

    @IBAction func delete(_: AnyObject) {
        let rows = tableView.selectedRowIndexes
        appDelegate.undoManager.beginUndoGrouping()
        rows.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            self.updateLocationAtRow(row, validLocation: false, latitude: 0,
                longitude: 0)
        }
        appDelegate.undoManager.endUndoGrouping()
        appDelegate.undoManager.setActionName("delete")
    }

    /// remove all items from the table
    ///
    /// - Parameter AnyObject: unused

    @IBAction func clear(_: AnyObject) {
        if !appDelegate.modified {
            images = []
            imageURLs.removeAll()
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

    @IBAction func interpolate(_: AnyObject) {
        struct LocnInfo {
            let lat: Double
            let lon: Double
            let timestamp: NSTimeInterval
        }
        var startInfo: LocnInfo!
        var endInfo: LocnInfo!

        // figure out our starting and ending points
        let rows = tableView.selectedRowIndexes
        rows.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            let image = self.images[row]
            if image.latitude != nil &&
               image.longitude != nil {
                let info = LocnInfo(lat: image.latitude!,
                                    lon: image.longitude!,
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
            print("\(distance) meters \(bearing)º at \(speed) meters/sec")
            appDelegate.undoManager.beginUndoGrouping()
            rows.enumerateIndexesUsingBlock {
                (row, _) -> Void in
                let image = self.images[row]
                let deltaTime = image.dateFromEpoch - startInfo.timestamp
                if deltaTime > 0 && deltaTime <= endInfo.timestamp &&
                   image.latitude == nil {
                    let deltaDist = deltaTime * speed
                    let (lat, lon) = destFromStart(lat: startInfo.lat, lon: startInfo.lon,
                                                   distance: deltaDist, bearing: bearing)
                    self.updateLocationAtRow(row, validLocation: true,
                                             latitude: lat, longitude: lon)
                }
            }
            appDelegate.undoManager.endUndoGrouping()
            appDelegate.undoManager.setActionName("interpolate locations")
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
//        webViewController.removeMapPin()
    }

    /// Reload a specific row.
    ///
    /// - Parameter row: the row to be refreshed.
    ///
    /// Update the latitude and longitude columns for the given row.

    func reloadRow(row: Int) {
        let latColumn = tableView.columnWithIdentifier("latitude")
        let columns = 2 // latitude and longitude
        let cols = NSIndexSet(indexesInRange: NSMakeRange(latColumn, columns))
        tableView.reloadDataForRowIndexes(NSIndexSet(index: row),
                                          columnIndexes: cols)
    }

    /// Update all selected rows with the given latitude and longitude
    ///
    /// - Parameter latitude: the new latitude for the selected items
    /// - Parameter longitude: the new longitude for the selected items
    ///
    /// Update all selected rows as a single undo group.

    func updateSelectedRows(latitude latitude: Double, longitude: Double) {
        let rows = tableView.selectedRowIndexes
        appDelegate.undoManager.beginUndoGrouping()
        rows.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            self.updateLocationAtRow(row, validLocation: true,
                latitude: latitude, longitude: longitude)
        }
        appDelegate.undoManager.endUndoGrouping()
    }


    // MARK: TableView delegate functions

    // don't allow rows with non images to be selected while still allowing
    // drags and ranges.

    func tableView(tableView: NSTableView,
                   selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet) -> NSIndexSet {
        let selectionIndexes = NSMutableIndexSet()
        proposedSelectionIndexes.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            if self.images[row].validImage {
               selectionIndexes.addIndex(row)
            }
        }
        return selectionIndexes
    }

    // match the image to the selected row

    func tableViewSelectionDidChange(notification: NSNotification) {

        // redraw last selected row in normal colors

        if let lastSelectedRow = self.lastSelectedRow {
            reloadRow(lastSelectedRow)
        }
        let row = tableView.selectedRow
        if row < 0 {
            imageWell.image = nil
//            webViewController.removeMapPin()
//            webViewController.itemSelected = false
        } else {
            let image = images[row]
            imageWell.image = image.image
            if image.latitude != nil && image.longitude != nil {
                reloadRow(row) // change color of selected row
//                webViewController.pinMapAtLatitude(image.latitude!,
//                                                   longitude: image.longitude!)
            } else {
//                webViewController.removeMapPin()
            }
//            webViewController.itemSelected = true
        }
    }

    //MARK: TableView data source functions

    // one row per image in the images array

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return images.count
    }

    // return view for requested column.

    func tableView(tableView: NSTableView,
                   viewForTableColumn tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        let image = images[row]
        var value = ""
        var tip: String? = nil
        if let id = tableColumn?.identifier {
            switch id {
            case "imageName":
                value = image.name ?? "Unknown"
                tip = image.path
            case "dateTime":
                value = image.date
            case "latitude":
                if let lat = image.latitude {
                    value = String(format: "% 2.6f", lat)
                }
            case "longitude":
                if let lon = image.longitude {
                    value = String(format: "% 2.6f", lon)
                }
            default:
                break
            }
            let colView =
                tableView.makeViewWithIdentifier(id, owner: nil) as! NSTableCellView
            colView.textField?.stringValue = value;
            if row == tableView.selectedRow {
                lastSelectedRow = row
                colView.textField?.textColor = NSColor.yellowColor()
            } else {
                lastSelectedRow = nil
                colView.textField?.textColor = nil
            }
            if tip != nil {
                colView.textField?.toolTip = tip!
            }
            if !image.validImage {
                colView.textField?.textColor = NSColor.grayColor()
            }
            return colView
        }
        return nil
    }

    //MARK: TableView drop functions

    // validate a proposed drop

    func tableView(aTableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation operation: NSTableViewDropOperation) -> NSDragOperation {

        let pb = info.draggingPasteboard()
        if let paths = pb.propertyListForType(NSFilenamesPboardType) as? [String!] {
            let fileManager = NSFileManager.defaultManager()
            for path in paths {
                if !fileManager.fileExistsAtPath(path) ||
                   imageURLs.contains(NSURL.fileURLWithPath(path)) {
                    return .None
                }
            }
            return .Link
        }
        return .None
    }

    // Add dropped files to the table

    func tableView(aTableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation operation: NSTableViewDropOperation) -> Bool {
        let pb = info.draggingPasteboard()
        if let paths = pb.propertyListForType(NSFilenamesPboardType) as? [String!] {
            var urls = [NSURL]()
            for path in paths {
                let fileURL = NSURL(fileURLWithPath: path)
                if !addURLsInFolder(fileURL, toURLs: &urls) {
                    urls.append(fileURL)
                }
            }
            return !addImages(urls)
        }
        return false
    }


}

extension TableViewController: MapViewDelegate {

    func mapViewMouseClicked(mapView: MapView!,
                             location: CLLocationCoordinate2D) {
        updateSelectedRows(latitude: location.latitude,
                            longitude: location.longitude)
        appDelegate.undoManager.setActionName("location change")
    }
}

//MARK: TableView extenstion for right click

/// in a table a right click will bring up a context menu.  I prefer that
/// the menu pertain to the row that was clicked. Do that by selecting the
/// row the mouse is on assuming the row is populated.  Once the row is
/// selected send the event to the super class for processing.  This is done
/// in a TableView extension.

extension NSTableView {
    public override func rightMouseDown(theEvent: NSEvent) {
        let localPoint = convertPoint(theEvent.locationInWindow, fromView: nil)
        let row = rowAtPoint(localPoint)
        if row >= 0 {
            if !isRowSelected(row) {
                selectRowIndexes(NSIndexSet(index: row),
                                 byExtendingSelection: false)
            }
        } else {
            deselectAll(self)
        }
        super.rightMouseDown(theEvent)
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