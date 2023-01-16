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
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @EnvironmentObject var vm: ViewModel
    @Binding var id: ImageModel.ID!

    @State private var latitude = ""
    @State private var longitude = ""
    @State private var alertPresented = false

    var body: some View {
        VStack {
            Form {
                Text("Image: \(vm[id].name)")
                    .bold()
                    .padding(.bottom, 10)

                LabeledContent("Latitude:") {
                    TextField("Latitude:", text: $latitude)
                        .labelsHidden()
                        .frame(maxWidth: 250)
                        .onSubmit {
                            if let lat =
                                latitude.validateLocation(range: 0...90,
                                                          reference: ["N", "S"]) {
                                latitude =
                                    latitudeToString(for: Coords(latitude: lat,
                                                                 longitude: 0.0))
                            }
                        }
                }
                .padding([.horizontal, .bottom])
                .help("Enter the latitude of the selected image.")

                LabeledContent("Longitude:") {
                    TextField("Longitude:", text: $longitude)
                        .labelsHidden()
                        .frame(maxWidth: 250)
                        .onSubmit {
                            if let lon =
                                longitude.validateLocation(range: 0...180,
                                                           reference: ["E", "W"]) {
                                longitude =
                                    longitudeToString(for: Coords(latitude: 0,
                                                                  longitude: lon))
                            }
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
                    if let lat =
                        latitude.validateLocation(range: 0...90,
                                                  reference: ["N", "S"]),
                       let lon =
                        longitude.validateLocation(range: 0...180,
                                                   reference: ["E", "W"]) {
                        updateSelectedImages(location: Coords(latitude: lat,
                                                              longitude: lon))
                        NSApplication.shared.keyWindow?.close()
                    } else {
                        alertPresented = true
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            latitude = latitudeToString(for: vm[id].location)
            longitude = longitudeToString(for: vm[id].location)
        }
       .onChange(of: id) {_ in
            latitude = latitudeToString(for: vm[id].location)
            longitude = longitudeToString(for: vm[id].location)
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

    func latitudeToString(for location: Coords?) -> String {
        if let location {
            switch coordFormat {
            case .deg:
                return String(format: "% 2.6f", location.latitude)
            case .degMin:
                return location.dm.latitude
            case .degMinSec:
                return location.dms.latitude
            }
        }
        return ""
    }

    func longitudeToString(for location: Coords?) -> String {
        if let location  {
            switch coordFormat {
            case .deg:
                return String(format: "% 2.6f", location.longitude)
            case .degMin:
                return location.dm.longitude
            case .degMinSec:
                return location.dms.longitude
            }
        }
        return ""
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
