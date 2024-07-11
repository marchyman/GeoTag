//
//  ImageMapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import SwiftUI
import SplitViews

struct ImageMapView: View {
    @AppStorage(AppSettings.splitVImageMapKey) var percent: Double = 0.60

    var body: some View {
        SplitVView(percent: $percent) {
            ImageView()
        } bottom: {
            MapWrapperView()
        }
    }
}

struct ImageMapView_Previews: PreviewProvider {
    static var previews: some View {
        ImageMapView()
    }
}
