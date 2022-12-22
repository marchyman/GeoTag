//
//  ContextMenuView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/22/22.
//

import SwiftUI

struct ContextMenuView: View {
    var body: some View {
        Group {
            Text("Cut")
            Text("Copy")
            Text("Paste")
            Text("Delete")
        }
        Divider()
        Group {
            Text("Show In Finder")
            Text("Locn From Track")
            Text("Modify Date/Time")
            Text("Modify Location")
        }
        Divider()
         Text("Clear Image List")
    }
}

struct ContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuView()
    }
}
