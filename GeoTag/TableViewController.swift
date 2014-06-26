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

    // MARK: startup

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // MARK: data source functions
    
    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        // Number of active rows
        return 0
    }

    func tableView(aTableView: NSTableView!,
                   objectValueForTableColumn aTableColumn: NSTableColumn!,
                   row rowIndex: Int) -> AnyObject! {
        // cell allocation stuff
        return nil
    }
}