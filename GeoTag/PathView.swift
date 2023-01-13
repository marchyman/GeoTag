//
//  PathView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/11/23.
//

import SwiftUI

// Make NSPathControl available with SwiftUI

struct PathView: NSViewRepresentable {
    @EnvironmentObject var vm: ViewModel

    class Coordinator: NSObject, NSPathControlDelegate {
        @Binding var backupURL: URL?

        init(backupURL: Binding<URL?>) {
            _backupURL = backupURL
        }

        @objc func action(sender: NSPathControl) {
            backupURL = sender.clickedPathItem?.url
        }
    }

    // Make the view coordinator.

    func makeCoordinator() -> Coordinator {
        return Coordinator(backupURL: $vm.backupURL)
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
        nsView.url = vm.backupURL
    }
}

struct PathView_Previews: PreviewProvider {
    static var previews: some View {
        PathView()
            .environmentObject(ViewModel())
    }
}
