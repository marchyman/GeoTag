//
//  PinAnnotationView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/23/23.
//

import MapKit

final class PinAnnotationView: MKAnnotationView {

    // MARK: Initialization

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        frame = CGRect(x: 0, y: 0, width: 40, height: 50)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)

        isEnabled = true
        canShowCallout = false
        isDraggable = true
        image = NSImage(named: "Pin")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
