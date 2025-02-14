//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// A horizontal view with two children separated by a dragable divider.
// The divider is stored as a percentage of the window width for the
// reserved for the right side of the view.

public struct SplitHView<Left: View, Right: View>: View {
    @Binding var percent: Double
    var left: Left
    var right: Right

    public init(
        percent: Binding<Double>,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self._percent = percent
        self.left = left()
        self.right = right()
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack {
                left
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                SplitHDividerView(percent: $percent, width: geometry.size.width)

                right
                    .frame(width: geometry.size.width * percent)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

// The dragable divider.

struct SplitHDividerView: View {
    @Binding var percent: Double
    let width: Double

    // clamp movement to within 20% of the view size.
    let minPercent = 0.20
    let maxPercent = 0.80

    var body: some View {
        ZStack {
            Rectangle()
                .background(.gray)
                .opacity(0.40)
                .frame(width: 2)
                .padding(.vertical, 8)
            Rectangle()
                .fill(.gray)
                .frame(width: 8, height: 8)
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(drag)
    }

    var drag: some Gesture {
        DragGesture(
            minimumDistance: 5,
            coordinateSpace: CoordinateSpace.global
        )
        .onChanged { val in
            percent = max(
                minPercent,
                min(1 - val.location.x / width, maxPercent))
        }
    }
}
