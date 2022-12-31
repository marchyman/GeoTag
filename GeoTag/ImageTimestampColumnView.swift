//
//  ImageTimestampColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageTimestampColumnView: View {
    @State private var showPopover = false
    @EnvironmentObject var vm: AppState
    let id: ImageModel.ID

    var body: some View {
        Text(vm[id].timeStamp)
            .foregroundColor(vm[id].isValid ? .primary : .gray)
            .onRightClick {
                print("Right Click -- on timestamp")
            }
            .onDoubleClick {
                showPopover.toggle()
            }
            .popover(isPresented: self.$showPopover) {
                Text("Popover -- this is where date/time change will take place.")
                    .padding()
            }
    }
}
