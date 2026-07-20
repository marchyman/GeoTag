// The UI test code also needs access and the way to do that is
// to put all of the ids in a separate file [this one] that can also be
// compiled by the test code.
//
// Views and View tests access the identifiers with
//
//  private let testIDs = TestIDs.SomeView.self
//
// and use them as `testIDs.someElementID` or testIDs.editButtonID(val)
// 

import Foundation

enum TestIDs {
    enum ContentView {
        static let imageInspectorViewID = "ContentView.view.imageInspectorView"
        static let imageViewAltID = "ContentView.view.imageViewAlt"
        static let imageViewID = "ContentView.view.imageView"
        static let imageTableViewAltID = "ContentView.view.imageTableViewAlt"
        static let imageTableViewID = "ContentView.view.imageTableView"
        static let photoPickerViewID = "ContentView.view.photoPickerView"
        static let inspectorButtonViewID = "ContentView.view.inspectorButtonView"
        static let mapSearchViewID = "ContentView.view.mapSearchView"
    }

    enum DismissModifier {
        static let dismissButtonID = "DismissModifier.button.dismiss"
    }

    enum AdjustTimeZoneView {
        static let cameraTimeZoneID = "AdjustTimeZoneView.picker.cameraTimeZone"
    }

    // warning: these items must be identical to those defined in
    // the RunLogView package.
    enum RunLogView {
        static let refreshID = "RunLogView.button.refresh"
        static let copyID = "RunLogView.button.copy"
    }

    enum SettingsView {
        static let closeID = "SettingsView.button.close"
        static let pathViewID = "SettingsView.view.pathView"
    }

    enum MapContextMenu {
        static let stylePickerID = "MapContextMenu.picker.mapStyle"
        static let pinOptionID = "MapContextMenu.view.pinOption"
    }

    enum TableColumns {
        static let nameID = "NameView.text.name"
        static let timestampID = "TimestampView.text.timestamp"
        static let latitudeID = "LatitudeView.text.latitude"
        static let longitudeID = "LongitudeView.text.longitude"
    }
}
