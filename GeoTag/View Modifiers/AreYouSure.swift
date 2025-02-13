//
//  AreYouSure.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/9/23.
//

import SwiftUI

struct AreYouSure: ViewModifier {
    @Environment(AppState.self) var state

    func body(content: Content) -> some View {
        @Bindable var state = state
        content
            .confirmationDialog("Are you sure?", isPresented: $state.presentConfirmation)
        {
            Button("I'm sure", role: .destructive) {
                if state.confirmationAction != nil {
                    state.confirmationAction!()
                }
            }
            Button("Cancel", role: .cancel) {}
                .keyboardShortcut(.defaultAction)
        } message: {
            let message = state.confirmationMessage ?? ""
            Text(message)
        }
    }
}

extension View {
    func areYouSure() -> some View {
        modifier(AreYouSure())
    }
}
