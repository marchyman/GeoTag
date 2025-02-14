//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

extension Color {
    static let changed = Color(nsColor: .systemGreen)
    static let mostSelected = Color(nsColor: .systemYellow)
}

extension ImageModel {
    var timestampTextColor: Color {
        if isValid {
            if dateTimeCreated == originalDateTimeCreated {
                return .primary
            }
            return .changed
        }
        return .secondary
    }

    var locationTextColor: Color {
        if isValid {
            if location == originalLocation {
                return .primary
            }
            return .changed
        }
        return .secondary
    }
}
