//
//  ModifyLocationView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ChangeLocationView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) private var dismiss

    let id: ImageModel.ID

    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var alertPresented = false

    var body: some View {
        VStack {
            Text("Change Location")
                .font(.largeTitle)
                .padding()

            Form {
                Text("Image: \(vm[id].name)")
                    .bold()
                    .padding(.bottom, 10)

                LabeledContent("Latitude:") {
                    TextField("Latitude:", value: $latitude, format: .latitude())
                        .labelsHidden()
                        .frame(maxWidth: 250)
                }
                .padding([.horizontal, .bottom])
                .help("Enter the latitude of the selected image.")

                LabeledContent("Longitude:") {
                    TextField("Longitude:", value: $longitude, format: .longitude())
                        .labelsHidden()
                        .frame(maxWidth: 250)
                }
                .padding([.horizontal, .bottom])
                .help("Enter the longitude of the selected image")
            }

            Spacer()

            HStack(alignment: .bottom) {
                Spacer()

                Button("Change") {
                    // ignore coords that weren't changed
                    if !(vm[id].location == nil && latitude == 0 && longitude == 0) {
                        if (0...90).contains(latitude.magnitude) &&
                           (0...180).contains(longitude.magnitude) {
                            let coords = Coords(latitude: latitude,
                                                longitude: longitude)
                            vm.update(id: id, location: coords)
                        } else {
                            alertPresented = true
                        }
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            latitude = vm[id].location?.latitude ?? 0.0
            longitude = vm[id].location?.longitude ?? 0.0
        }
       .alert("Coordinate Error",
              isPresented: $alertPresented) {
        } message: {
            Text("""
                 Latitude and Longitude coordinates may entered in several different ways:

                 dd.dddd R
                 dd mm.mmmm R
                 dd mm ss.ssss R

                 dd = degrees
                 mm = minutes
                 ss = seconds
                 R = N, S, E, or W reference.

                 Latitude must be between 0 and 90°. Longitude must be between 0 and 180°.
                 °, ', and " marks are ignored. The R value is optional.  N (lat) or E (lon)
                 are assumed.  Entry of a negative number of degrees will use a S or W reference.
                 """)
        }
    }
}

//struct ChangeLocationView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChangeLocationView()
//            .environmentObject(ViewModel())
//    }
//}
