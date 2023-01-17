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
                .padding()

            if vm.mostSelected != nil {
                AdjustLocationView(id: $vm.mostSelected)
            }
        }
    }
}

struct AdjustLocationView: View {
    @EnvironmentObject var vm: ViewModel
    @Binding var id: ImageModel.ID!

    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var alertPresented = false

    var body: some View {
        VStack {
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

                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    // ignore coords that weren't changed
                    if !(vm[id].location == nil && latitude == 0 && longitude == 0) {
                        if (0...90).contains(latitude.magnitude) &&
                           (0...180).contains(longitude.magnitude) {
                            let coords = Coords(latitude: latitude,
                                                longitude: longitude)
                            updateSelectedImages(location: coords)
                        } else {
                            alertPresented = true
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            latitude = vm[id].location?.latitude ?? 0.0
            longitude = vm[id].location?.longitude ?? 0.0
        }
       .onChange(of: id) {_ in
           latitude = vm[id].location?.latitude ?? 0.0
           longitude = vm[id].location?.longitude ?? 0.0
        }
       .alert("Coordinate Format Error",
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

                 The R value is optional.  N (lat) or E (lon) are assumed.  Entry of a negative number of degrees will use a S or W reference.
                 """)
        }
    }

    func updateSelectedImages(location: Coords) {
        vm.undoManager.beginUndoGrouping()
        for id in vm.selection {
            vm.update(id: id, location: location)
        }
        vm.undoManager.endUndoGrouping()
        vm.undoManager.setActionName("modify location")

    }
}

struct _ModifyLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyLocationView()
            .environmentObject(ViewModel())
    }
}
