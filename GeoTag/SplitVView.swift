//
//  SplitVView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 3/6/24.
//

import SwiftUI

// A horizontal view with two children separated by a dragable divider.
// The divider is stored as a percentage of the window height for the
// reserved for the right side of the view.

struct SplitVView<Top: View, Bottom: View>: View {
    @Binding var percent: Double
    @ViewBuilder var top: () -> Top
    @ViewBuilder var bottom: () -> Bottom

    init(percent: Binding<Double>,
         @ViewBuilder top: @escaping () -> Top,
         @ViewBuilder bottom: @escaping () -> Bottom) {
        self._percent = percent
        self.top = top
        self.bottom = bottom
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                top()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                SplitVDividerView(percent: $percent, height: geometry.size.height)

                bottom()
                    .frame(height: geometry.size.height * percent)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// The dragable divider.

struct SplitVDividerView: View {
    @Binding var percent: Double
    let height: Double

    // clamp movement to within 20% of the view height.
    let minPercent = 0.20
    let maxPercent = 0.80

    var body: some View {
        ZStack {
            Rectangle()
                .background(.gray)
                .opacity(0.40)
                .frame(height: 2)
                .padding(.trailing, 8)
            Rectangle()
                .fill(.gray)
                .frame(width: 8, height: 8)
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(drag)
    }

    var drag: some Gesture {
        DragGesture(minimumDistance: 5,
                    coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                percent = max(minPercent,
                              min(1 - val.location.y / height, maxPercent))
            }
    }
}
