//
//  TableController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/24/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa

@objc(TableViewController)
class TableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var appDelegate: AppDelegate
    @IBOutlet var tableView: NSTableView
    @IBOutlet var imageWell: NSImageView

    var images = [ImageData]()

    // startup

    override func viewDidLoad() {       // 10.10 and later
        super.viewDidLoad()
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
            reload()
        }
        return duplicateFound
    }

    // menu actions

    override func validateMenuItem(menuItem: NSMenuItem!) -> Bool {
        switch menuItem.action {
        case Selector("selectAll:"):
            return images.count > 0
        case Selector("clear:"):
            return images.count > 0 && !appDelegate.isModified()
        case Selector("discard:"):
            return appDelegate.isModified()
        case Selector("cut:"), Selector("copy:"), Selector("paste:"), Selector("delete:"):
            return tableView.selectedRow != -1
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
        reload()
    }

    @IBAction func cut(AnyObject) {
        println(__FUNCTION__)
    }

    @IBAction func copy(AnyObject) {
        println(__FUNCTION__)
    }

    @IBAction func paste(AnyObject) {
        println(__FUNCTION__)
    }

    @IBAction func delete(AnyObject) {
        // range 2, 2 is that start col and number of cols for the location
        // hardcoding is (hopefully) a temporary thing ;;;
        let cols = NSIndexSet(indexesInRange: NSMakeRange(2, 2))
        let rows = tableView.selectedRowIndexes
        rows.enumerateIndexesUsingBlock {
            (row: Int, stop: UnsafePointer<ObjCBool>) -> Void in
            // remove marker from map ;;;
            self.images[row].clearLocation()
            self.tableView.reloadDataForRowIndexes(NSIndexSet(index: row),
                columnIndexes: cols)
            self.appDelegate.modified(true)
        }
    }

    @IBAction func clear(AnyObject) {
        if !appDelegate.isModified() {
            images = []
            reload()
        }
    }

    // reload the table, clear the image well and remove any markers
    // from the map view

    func reload() {
        tableView.reloadData()
        imageWell.image = nil
        // update map here
    }

    // delegate functions

//    func tableView(tableView: NSTableView!,
//        selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet!) -> NSIndexSet! {
//        println("\(proposedSelectionIndexes)")
//        return proposedSelectionIndexes
//    }

    func tableViewSelectionDidChange(notification: NSNotification!) {
        let row = tableView.selectedRow
        imageWell.image = row < 0 ? nil : images[row].image
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
            var colView = tableView.makeViewWithIdentifier(id, owner: nil) as NSTableCellView
            colView.textField.stringValue = value;
            return colView
        }
        return nil
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
                selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            }
        } else {
            deselectAll(self)
        }
        super.rightMouseDown(theEvent)
    }
}