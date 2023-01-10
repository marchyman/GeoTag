//
//  ImageMapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import SwiftUI

struct ImageMapView: View {
    @ObservedObject public var control: DividerControl

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ImageView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    MapPaneView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: geometry.size.height * control.dividerPosition)
                }
                DividerView(control: control, geometry: geometry)
            }
        }
    }
}

struct ImageMapView_Previews: PreviewProvider {
    static var previews: some View {
        ImageMapView(control: DividerControl())
    }
}
