//
//  ModifyLocationView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ChangeLocationView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var avm: AppViewModel
    let id: ImageModel.ID

    @State private var latitude: Double?
    @State private var longitude: Double?

    @State private var alertPresented = false

    var body: some View {
        VStack {
            Text("Change Location")
                .font(.largeTitle)
                .padding()

            Form {
                Text("Image: \(avm[id].name)")
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
                    if let lat = latitude, let lon = longitude {
                        if (0...90).contains(lat.magnitude) &&
                           (0...180).contains(lon.magnitude) {
                            let location = Coords(latitude: lat, longitude: lon)
                            if location != avm[id].location {
                                avm.update(id: id, location: location)
                            }
                            dismiss()
                        } else {
                            alertPresented.toggle()
                        }
                    } else if latitude == nil && longitude == nil {
                        avm.update(id: id, location: nil)
                        dismiss()
                    } else {
                        alertPresented.toggle()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            latitude = avm[id].location?.latitude
            longitude = avm[id].location?.longitude
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

// struct ChangeLocationView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChangeLocationView()
//            .environmentObject(ViewModel())
//    }
// }
