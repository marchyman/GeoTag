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

    @IBOutlet var tableView: NSTableView
    @IBOutlet var imageWell: NSImageView

    var images = [ImageData]()

    // startup

    override func viewDidLoad() {       // 10.10 and later
        super.viewDidLoad()
    }

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
            tableView.reloadData()
        }
        return duplicateFound
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