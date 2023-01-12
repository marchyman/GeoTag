//
//  PathView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/11/23.
//

import SwiftUI

// Make NSPathControl available with SwiftUI

struct PathView: NSViewRepresentable {
    @ObservedObject var appSettings: AppSettings

    class Coordinator: NSObject, NSPathControlDelegate {
        @ObservedObject var appSettings: AppSettings

        init(appSettings: ObservedObject<AppSettings>) {
            _appSettings = appSettings
        }

        @objc func action(sender: NSPathControl) {
            appSettings.backupURL = sender.clickedPathItem?.url
        }
    }

    // Make the view coordinator.

    func makeCoordinator() -> Coordinator {
        return Coordinator(appSettings: _appSettings)
    }

    func makeNSView(context: Context) -> NSPathControl {
        let pathControl = NSPathControl()
        pathControl.pathStyle = .popUp
        pathControl.delegate = context.coordinator
        pathControl.placeholderString = "Please select folder for image backups"
        pathControl.target = context.coordinator
        pathControl.action = #selector(Coordinator.action)
        return pathControl
    }

    func updateNSView(_ nsView: NSPathControl, context: Context) {
        nsView.url = appSettings.backupURL
    }
}

struct PathView_Previews: PreviewProvider {
    static var previews: some View {
        PathView(appSettings: AppSettings())
    }
}
