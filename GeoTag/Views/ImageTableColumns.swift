import Coords
import ImageData
import SwiftUI

// ImageTableView column views

struct NameView: View {
    let image: ImageData
    let isSelected: Bool

    var body: some View {
        Text(image.name)
            .accessibilityIdentifier(TestIDs.TableColumns.nameID)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(
                isSelected
                    ? .mostSelected
                    : image.updatable
                        ? .primary
                        : .secondary
            )
            .truncationMode(.middle)
            .help("Full path: \(image.fullPath)")
    }
}

struct TimestampView: View {
    let image: ImageData

    var body: some View {
        Text(image.metadata.timestamp)
            .accessibilityIdentifier(TestIDs.TableColumns.timestampID)
            .foregroundColor(image.timestampTextColor)
    }
}
struct LatitudeView: View {
    let image: ImageData
    @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg

    var body: some View {
        Text(image.metadata.formattedLatitude)
            .accessibilityIdentifier(TestIDs.TableColumns.latitudeID)
            .foregroundColor(image.locationTextColor)
            .help(image.metadata.formattedElevation)
    }
}

struct LongitudeView: View {
    let image: ImageData
    @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg

    var body: some View {
        Text(image.metadata.formattedLongitude)
            .accessibilityIdentifier(TestIDs.TableColumns.longitudeID)
            .foregroundColor(image.locationTextColor)
            .help(image.metadata.formattedElevation)
    }
}
