//
//  ModifyDateTimeView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ModifyDateTimeView: View {
    @EnvironmentObject var vm: AppState

    var body: some View {
        VStack {
            Text("Modify Date/Time")
            if let context = vm.menuContext {
                Text("Context: \(context)")
            } else if let selected = vm.mostSelected {
                Text("Most selected: \(selected)")
            }
        }
    }
}

struct ModifyDateTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyDateTimeView()
            .environmentObject(AppState())
    }
}
