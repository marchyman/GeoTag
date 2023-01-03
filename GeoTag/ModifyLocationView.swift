//
//  ModifyLocationView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ModifyLocationView: View {
    @EnvironmentObject var vm: AppState

    var body: some View {
        VStack {
            Text("Modify Location View")
            if let context = vm.menuContext {
                Text("Context: \(context)")
            } else if let selected = vm.mostSelected {
                Text("Most selected: \(selected)")
            }
        }
    }
}

struct _ModifyLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyLocationView()
            .environmentObject(AppState())
    }
}
