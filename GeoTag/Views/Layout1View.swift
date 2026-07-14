// The "normal" layout of the GeoTag main window

import SplitHView
import SplitVView
import SwiftUI

struct Layout1: View {
    @Binding var inspectorPresented: Bool
    @Binding var spinnerEnabled: Bool
    @AppStorage(Self.splitHNormalKey) var hNormal = 0.45
    @AppStorage(Self.splitVNormalKey) var vNormal = 0.60

    private let testIDs = TestIDs.ContentView.self

    var body: some View {
        SplitHView(percent: $hNormal) {
            ImageTableView(inspectorPresented: $inspectorPresented)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(testIDs.imageTableViewID)
                .overlay {
                    if spinnerEnabled {
                        ProgressView("Processing files...")
                    }
                }
        } right: {
            SplitVView(percent: $vNormal) {
                ImageView()
                    .accessibilityIdentifier(testIDs.imageViewID)
            } bottom: {
                MapWithSearchView()
            }
        }
    }
}

extension Layout1 {
    static let splitHNormalKey = "SplitHNormalPercent"
    static let splitVNormalKey = "SplitVNormalPercent"
}
