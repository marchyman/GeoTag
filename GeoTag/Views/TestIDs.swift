// Each view will extend this enum adding accessibilityIdentifiers 
// used by the view. In a perfect world it would look like this with
// the extension inside the view source code.
//
// extension TestIDs {
//     enum SomeView {
//         static let someElementID = "SomeView.view.blah"
//         static let anotherElementID = "SomeView.button.add"
//         static func editButtonID(_ name: String) -> String {
//             "SomeView.button.edit \(name)"
//         }
//     }
// }

// Alas, the UI test code also needs access and the way to do that is
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
    }
}
