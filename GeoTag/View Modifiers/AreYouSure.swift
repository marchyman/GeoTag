//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// modifier designed to add a confirmation dialog to any view that uses it.

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
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
                .keyboardShortcut(.cancelAction)
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
