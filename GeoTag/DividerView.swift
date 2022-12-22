//
//  DividerView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/21/22.
//

import SwiftUI

public class DividerControl: ObservableObject {
    @AppStorage(AppSettings.dividerPositionKey) var dividerPosition: Double = 0.50

    @Published var currentOffset: CGFloat = 0
    @Published var previousOffset: CGFloat = 0
}

// A draggable divider that moves vertically within a view.

struct DividerView: View {
    @ObservedObject var control: DividerControl
    var geometry: GeometryProxy

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
        VStack {
            Rectangle()
                .foregroundColor(Color(NSColor.separatorColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 2)
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
        let height = control.previousOffset + gesture.translation.height
        control.currentOffset = max(negativeCap, min(positiveCap, height))
        control.dividerPosition =
            (geometry.size.height / 2 - control.currentOffset) / geometry.size.height
    }

    func dragEnded(_ gesture: DragGesture.Value) {
        control.previousOffset = control.currentOffset
    }
}

//struct DividerView_Previews: PreviewProvider {
//    static var previews: some View {
//        DividerView()
//    }
//}
