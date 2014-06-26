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
        return 0
    }

    func tableView(tableView: NSTableView!,
                 tableColumn: NSTableColumn!,
                         row: Int) -> NSView! {

        return nil
    }
}