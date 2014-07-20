//
//  TableController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/24/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa
import MapKit

@objc(TableViewController)
class TableViewController: NSViewController, NSTableViewDelegate,
    NSTableViewDataSource, MapViewDelegate {

    @IBOutlet var appDelegate: AppDelegate
    @IBOutlet var tableView: NSTableView
    @IBOutlet var imageWell: NSImageView
    @IBOutlet var mapViewController: MapViewController

    var images = [ImageData]()

    // startup

    override func viewDidLoad() {       // 10.10 and later
        super.viewDidLoad()
        // this would be a good place to initialize an undo manager
    }

    override func awakeFromNib() {
        // can't make clickDelegate an @IBOutlet; wire it up here

        mapViewController.mapView.clickDelegate = self
        tableView.registerForDraggedTypes([NSFilenamesPboardType]);

    }

    // poulating the table

    func isDuplicateImage(url: NSURL) -> Bool {
        for image in images {
            if url.path == image.path {
                return true
            }
        }
        return false
    }

    func addImages(urls: [NSURL]) -> Bool {
        var reloadNeeded = false
        var duplicateFound = false
        for url in urls {
            if isDuplicateImage(url) {
                duplicateFound = true
            } else {
                images += ImageData(url: url)
                reloadNeeded = true
            }
        }
        if reloadNeeded {
            reloadAllRows()
        }
        return duplicateFound
    }

    // location update with undo/redo support.
    // Note: The system can not handle optional types when used with
    // prepareWithInvocationTarget.  A tuple will not work, either.  Both
    // will cause an EXC_BAD_ACCESS to be generated (true as of Xcode 6 beta 3)

    func updateLocationAtRow(row: Int, validLocation: Bool, latitude: Double,
                             longitude: Double, modified: Bool) {
        var oldValidLocation: Bool
        var oldLatitude: Double
        var oldLongitude: Double
        let image = images[row]
        if image.latitude && image.longitude {
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
            longitude: oldLongitude, modified: appDelegate.isModified())
        if validLocation {
            image.setLatitude(latitude, longitude: longitude)
        } else {
            image.setLatitude(nil, longitude: nil)
        }
        reloadRow(row)
        appDelegate.modified(modified)
    }

    // menu actions

    override func validateMenuItem(menuItem: NSMenuItem!) -> Bool {
        switch menuItem.action {
        case Selector("selectAll:"):
            // OK as long as there is at least one entry in the table
            return images.count > 0
        case Selector("clear:"):
            // OK if the table is populated and no changes pending
            return images.count > 0 && !appDelegate.isModified()
        case Selector("discard:"):
            // OK if there are changes pending
            return appDelegate.isModified()
        case Selector("cut:"), Selector("copy:"):
            // OK if only one row with a valid location selected
            if tableView.numberOfSelectedRows == 1 {
                let image = images[tableView.selectedRow]
                if (image.latitude && image.longitude) {
                    return true
                }
            }
        case Selector("paste:"):
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
        case Selector("delete:"):
            // OK if at least one row selected
            return tableView.numberOfSelectedRows > 0
        default:
            println("default for item \(menuItem)")
        }
        return false
    }

    @IBAction func discard(AnyObject) {
        for image in images {
            image.revertLocation()
        }
        appDelegate.modified(false)
        reloadAllRows()
    }

    @IBAction func cut(obj: AnyObject) {
        copy(obj)
        delete(obj)
        appDelegate.undoManager.setActionName("cut")
    }

    @IBAction func copy(AnyObject) {
        let row = tableView.selectedRow
        let pb = NSPasteboard.generalPasteboard()
        pb.declareTypes([NSPasteboardTypeString], owner: self)
        pb.setString(images[row].stringRepresentation,
                     forType: NSPasteboardTypeString)
    }

    @IBAction func paste(AnyObject) {
        let pb = NSPasteboard.generalPasteboard()
        if let pasteVal = pb.stringForType(NSPasteboardTypeString) {
            // pasteVal should look like "lat lon"
            let values = pasteVal.componentsSeparatedByString(" ")
            if values.count == 2 {
                let latitude = values[0].doubleValue
                let longitude = values[1].doubleValue
                updateSelectedRows(latitude, longitude: longitude)
                appDelegate.undoManager.setActionName("paste")
            }
        }
    }

    @IBAction func delete(AnyObject) {
        let rows = tableView.selectedRowIndexes
        appDelegate.undoManager.beginUndoGrouping()
        rows.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            self.mapViewController.removeMapPin()
            self.updateLocationAtRow(row, validLocation: false, latitude: 0,
                longitude: 0, modified: true)
        }
        appDelegate.undoManager.endUndoGrouping()
        appDelegate.undoManager.setActionName("delete")
    }

    @IBAction func clear(AnyObject) {
        if !appDelegate.isModified() {
            images = []
            reloadAllRows()
        }
    }

    // Functions to reload the table

    // Reload all rows.  Clear the image well and remove any markers
    // from the map view.  Reloading all rows always clears undo
    // actions.
    func reloadAllRows() {
        appDelegate.undoManager.removeAllActions()
        tableView.reloadData()
        imageWell.image = nil
        mapViewController.removeMapPin()
    }

    // Reloading a specific row.  Only the latitude and longitude columns
    // will need refreshing
    func reloadRow(row: Int) {
        let latColumn = tableView.columnWithIdentifier("latitude")
        let columns = 2 // latitude and longitude
        let cols = NSIndexSet(indexesInRange: NSMakeRange(latColumn, columns))
        tableView.reloadDataForRowIndexes(NSIndexSet(index: row),
                                          columnIndexes: cols)
    }

    // Update all selected rows with the given latitude and longitude
    func updateSelectedRows(latitude: Double, longitude: Double) {
        let rows = tableView.selectedRowIndexes
        appDelegate.undoManager.beginUndoGrouping()
        rows.enumerateIndexesUsingBlock {
            (row, _) -> Void in
            let image = self.images[row]
            self.updateLocationAtRow(row, validLocation: true,
                latitude: latitude, longitude: longitude,
                modified: true)
            self.mapViewController.pinMapAtLatitude(image.latitude!,
                longitude: image.longitude!)
        }
        appDelegate.undoManager.endUndoGrouping()
    }

    // MapView delegate functions
    func mapViewMouseClicked(mapView: MapView!,
                             location: CLLocationCoordinate2D) {
        updateSelectedRows(location.latitude, longitude: location.longitude)
        appDelegate.undoManager.setActionName("set location")
    }


    // delegate functions

//    func tableView(tableView: NSTableView!,
//        selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet!) -> NSIndexSet! {
//        println("\(proposedSelectionIndexes)")
//        return proposedSelectionIndexes
//    }

    func tableViewSelectionDidChange(notification: NSNotification!) {
        let row = tableView.selectedRow
        if row < 0 {
            imageWell.image = nil
            mapViewController.removeMapPin()
        } else {
            let image = images[row]
            imageWell.image = image.image
            if image.latitude && image.longitude {
                mapViewController.pinMapAtLatitude(image.latitude!,
                                                   longitude: image.longitude!)
            } else {
                mapViewController.removeMapPin()
            }
        }
    }

    // data source functions
    
    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return images.count
    }

    func tableView(tableView: NSTableView!,
        viewForTableColumn tableColumn: NSTableColumn!,
        row: Int) -> NSView! {
        let image = images[row]
        var value = ""
        if let id = tableColumn.identifier {
            switch id {
            case "imageName":
                value = image.name
            case "dateTime":
                value = image.date
            case "latitude":
                if let lat = image.latitude {
                    value = NSString(format: "% 2.6f", lat)
                }
            case "longitude":
                if let lon = image.longitude {
                    value = NSString(format: "% 2.6f", lon)
                }
            default:
                break
            }
            var colView =
                tableView.makeViewWithIdentifier(id, owner: nil) as NSTableCellView
            colView.textField.stringValue = value;
            return colView
        }
        return nil
    }

    func tableView(aTableView: NSTableView!,
                   validateDrop info: NSDraggingInfo!,
                   proposedRow row: Int,
                   proposedDropOperation operation: NSTableViewDropOperation) -> NSDragOperation {

        if row < images.count {
            return .None
        }
        let pb = info.draggingPasteboard()
        if let paths = pb.propertyListForType(NSFilenamesPboardType) as? [String!] {
            let fileManager = NSFileManager.defaultManager()
            for path in paths {
                var dir: ObjCBool = false
                if fileManager.fileExistsAtPath(path, isDirectory: &dir) {
                    if dir == true ||
                       isDuplicateImage(NSURL(fileURLWithPath: path)) {
                        return .None
                    }
                }
            }
            return .Link
        }
        return .None
    }

    func tableView(aTableView: NSTableView!,
                   acceptDrop info: NSDraggingInfo!,
                   row: Int,
                   dropOperation operation: NSTableViewDropOperation) -> Bool {
        let pb = info.draggingPasteboard()
        if let paths = pb.propertyListForType(NSFilenamesPboardType) as? [String!] {
            var urls = [NSURL]()
            for path in paths {
                urls += NSURL(fileURLWithPath: path)
            }
            return !addImages(urls)
        }
        return false
    }
}

/// in a table a right click will bring up a context menu.  I prefer that
/// the menu pertain to the row that was clicked. Do that by selecting the
/// row the mouse is on assuming the row is populated.  Once the row is
/// selected send the event to the super class for processing.  This is done
/// in a TableView extension.

extension NSTableView {
    override func rightMouseDown(theEvent: NSEvent!) {
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

/// Convert a string to a double through a cast to NSString.
/// Used in paste code to handle lat and lon as a string value.

extension String {
    var doubleValue: Double {
    return (self as NSString).doubleValue
    }
}