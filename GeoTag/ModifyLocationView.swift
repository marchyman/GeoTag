//
//  ModifyLocationView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ModifyLocationView: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        VStack {
            Text("Modify Location")
                .font(.largeTitle)
                .padding(.top)

            if vm.mostSelected != nil {
                AdjustLocationView(id: $vm.mostSelected)
            }
        }
    }
}

struct AdjustLocationView: View {
    @EnvironmentObject var vm: ViewModel
    @Binding var id: ImageModel.ID!

    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        VStack {
            Form {
                LabeledContent("Latitude:") {
                    TextField("Latitude:", text: $latitude)
                        .labelsHidden()
                        .frame(maxWidth: 250)
                        .help("Enter the latitude of the selected image.")
                        .onSubmit {
                        }
                }
                .padding([.horizontal, .bottom])
                .help("Enter the latitude of the selected image.")

                LabeledContent("Longitude:") {
                    TextField("Longitude:", text: $longitude)
                        .labelsHidden()
                        .frame(maxWidth: 250)
                        .help("Enter the longitude of the selected image.")
                        .onSubmit {
                        }
                }
                .padding([.horizontal, .bottom])
                .help("Enter the longitude of the selected image")
            }

            Spacer()

            HStack(alignment: .bottom) {
                Spacer()

                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    // do update here
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }


}

struct _ModifyLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyLocationView()
            .environmentObject(ViewModel())
    }
}
