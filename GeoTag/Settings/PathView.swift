//
//  PathView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/11/23.
//

import SwiftUI

// Make NSPathControl available with SwiftUI

struct PathView: NSViewRepresentable {
    @Binding var url: URL?

    class Coordinator: NSObject, NSPathControlDelegate {
        @Binding var backupURL: URL?

        init(backupURL: Binding<URL?>) {
            _backupURL = backupURL
        }

        @MainActor @objc func action(sender: NSPathControl) {
            backupURL = sender.clickedPathItem?.url
        }

        @objc func pathControl(_ pathControl: NSPathControl,
                               willDisplay openPanel: NSOpenPanel) {
            openPanel.canCreateDirectories = true
        }
    }

    // Make the view coordinator.

    func makeCoordinator() -> Coordinator {
        return Coordinator(backupURL: $url)
    }

    func makeNSView(context: Context) -> NSPathControl {
        let pathControl = NSPathControl()
        pathControl.url = url
        pathControl.pathStyle = .popUp
        pathControl.delegate = context.coordinator
        pathControl.placeholderString = "Please select folder for image backups"
        pathControl.target = context.coordinator
        pathControl.action = #selector(Coordinator.action)
        return pathControl
    }

    func updateNSView(_ nsView: NSPathControl, context: Context) { }
}

#Preview {
    @Previewable @State var url: URL?
    PathView(url: $url)
}
