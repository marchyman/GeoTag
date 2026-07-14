// The "alternate" layout of the GeoTag main window

import SplitHView
import SplitVView
import SwiftUI

struct Layout2: View {
    @Binding var inspectorPresented: Bool
    @Binding var spinnerEnabled: Bool
    @AppStorage(Self.splitHAlternateKey) var hAlternate = 0.55
    @AppStorage(Self.splitVAlternateKey) var vAlternate = 0.40

    private let testIDs = TestIDs.ContentView.self

    var body: some View {
        SplitHView(percent: $hAlternate) {
            SplitVView(percent: $vAlternate) {
                ImageTableView(inspectorPresented: $inspectorPresented)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(testIDs.imageTableViewID)
                    .overlay {
                        if spinnerEnabled {
                            ProgressView("Processing files...")
                        }
                    }
            } bottom: {
                ImageView()
                    .accessibilityIdentifier(testIDs.imageViewID)
            }
        } right: {
            MapWithSearchView()
        }
    }
}

extension Layout2 {
    static let splitHAlternateKey = "SplitHAlternatePercent"
    static let splitVAlternateKey = "SplitVAlternatePercent"
}
