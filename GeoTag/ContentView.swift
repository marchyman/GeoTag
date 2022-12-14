//
//  ContentView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/9/22.
//

import SwiftUI

// look and feel values
let borderColor = Color.gray
let minWidth = 400.0
let minHeight = 800.0

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HSplitView {
            ImageTableView(images: $appState.images)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VSplitView {
                Text("Image View goes here")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("Map View goes here")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: minWidth, minHeight: minHeight)
        .border(borderColor)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
