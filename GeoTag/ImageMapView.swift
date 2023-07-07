//
//  ImageMapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import SwiftUI

struct ImageMapView: View {
    @AppStorage(AppSettings.dividerPositionKey) var dividerPosition: Double = 0.60

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ImageView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    MapPaneView()
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * dividerPosition)
                }
            }
        }
    }
}

struct ImageMapView_Previews: PreviewProvider {
    static var previews: some View {
        ImageMapView()
    }
}
