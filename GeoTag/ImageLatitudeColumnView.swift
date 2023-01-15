//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLatitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @EnvironmentObject var vm: ViewModel
    @Environment(\.openWindow) var openWindow
    let id: ImageModel.ID

    var body: some View {
        Text(latitudeToString())
            .foregroundColor(textColor())
            .frame(minWidth: coordMinWidth)
            .onDoubleClick {
                vm.menuContext = id
                openWindow(id: GeoTagApp.modifyLocation)
            }
            .help(vm.elevationAsString(id: id))
    }

    func latitudeToString() -> String {
        if let location = vm[id].location {
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

    func textColor() -> Color {
        if vm[id].isValid {
            if vm[id].location == vm[id].originalLocation {
                return .primary
            }
            return .changed
        }
        return .secondary
    }
}

struct ImageLatitudeColumnView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        ImageLatitudeColumnView(id: image.id)
            .environmentObject(ViewModel(images: [image]))
    }
}
