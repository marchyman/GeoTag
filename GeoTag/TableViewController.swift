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
    
    // startup

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // data source functions
    
    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        // Number of active rows
        println(__FUNCTION__ + ": for table view \(tableView)")
        return 1
    }

    func tableView(tableView: NSTableView!,
        viewForTableColumn tableColumn: NSTableColumn!,
        row: Int) -> NSView! {
        if let id = tableColumn.identifier {
            switch id {
                case "imageName":
                     println("imageName")

                case "dateTime":
                    println("dateTime")

                case "latitude":
                    println("latitude")
                
                case "longitude":
                    println("longitude")

            default:
                    println("unknown id")
            }
            var colView = tableView.makeViewWithIdentifier(id, owner: nil) as NSTableCellView
            colView.textField.stringValue = "Test " + id;    // test code
            return colView
        }
        return nil
    }
}