//
//  AdjustTimezoneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct AdjustTimezoneView: View {
    @EnvironmentObject var vm: AppState

    var body: some View {
        VStack {
            Text("Adjust Time Zone")
        }
    }
}

struct AdjustTimezoneView_Previews: PreviewProvider {
    static var previews: some View {
        AdjustTimezoneView()
            .environmentObject(AppState())
    }
}
