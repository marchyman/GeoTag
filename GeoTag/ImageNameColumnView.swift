//
//  ImageNameColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/15/22.
//

import SwiftUI

struct ImageNameColumnView: View {
    @EnvironmentObject var vm: AppState
    let id: ImageModel.ID

    var body: some View {
        Text(vm[id].name + ((vm[id].sandboxXmpURL == nil) ? "" : "*"))
            .foregroundColor(vm[id].isValid ? .primary : .gray)
            .help("Full path: \(vm[id].fileURL.path)")
    }

}
