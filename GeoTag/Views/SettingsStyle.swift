// Form style for settings

import SwiftUI

struct SettingsFormStyle: FormStyle {
    func makeBody(configuration: Configuration) -> some View {
        Grid {
            Group(sections: configuration.content) { sections in
                ForEach(sections) { section in
                    GridRow(alignment: .firstTextBaseline) {
                        section.header
                            .font(.headline)
                            .gridColumnAlignment(.trailing)
                        VStack(alignment: .leading) {
                            section.content
                            section.footer
                                .foregroundStyle(.primary)
                        }
                        .gridColumnAlignment(.leading)
                    }
                    if section.id != sections.last?.id {
                        Divider()
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
        }
    }
}
