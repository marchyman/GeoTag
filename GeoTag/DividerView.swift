//
//  DividerView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import Combine
import SwiftUI

// make this an observable object as otherwise updates to dividerPosition
// do not cause view updates in ImageMapView.

public class DividerControl: ObservableObject {
    @AppStorage(AppSettings.dividerPositionKey) var dividerPosition: Double = 0.60
}

// A draggable divider that moves vertically within a view.

struct DividerView: View {
    @ObservedObject var control: DividerControl
    var geometry: GeometryProxy

    @State private var currentOffset: CGFloat = 0
    @State private var previousOffset: CGFloat = 0

    // The divider is offset from the middle of the view. Max divider movement
    // is capped to +/- 70% of the view height (-35% to +35% of offset)
    var positiveCap: CGFloat {
        geometry.size.height * 0.35
    }
    var negativeCap: CGFloat {
        -positiveCap
    }

    // calculate the offset from the middle of the dividerPosition
    var offset: CGFloat {
        let height = geometry.size.height
        return height / 2 - (control.dividerPosition * height)
    }

    var body: some View {
        Divider()
            .frame(minHeight: 5)
            .onHover { isHovered in
                if (isHovered) {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .offset(y: offset)
            .gesture(drag)
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged(dragChanged)
            .onEnded(dragEnded)
    }

    func dragChanged(_ gesture: DragGesture.Value) {
        let height = previousOffset + gesture.translation.height
        currentOffset = max(negativeCap, min(positiveCap, height))
        control.dividerPosition =
            (geometry.size.height / 2 - currentOffset) / geometry.size.height
    }

    func dragEnded(_ gesture: DragGesture.Value) {
        // update final value
        dragChanged(gesture)
        // and save the offset for future drags
        previousOffset = currentOffset
    }
}

//struct DividerView_Previews: PreviewProvider {
//    static var previews: some View {
//        DividerView()
//    }
//}
