import Coords
import Foundation
import GpxTrackLog
import ImageData
import UDF

@MainActor
enum LocationHelper {

    // struct to hold id and timestamp of an image to look location

    struct LocationById: Equatable {
        var id: ImageData.ID
        var timestamp: TimeInterval
        var coords: Coords?
        var elevation: Double?
    }

    @MainActor
    @discardableResult
    static func locationFromTrack(_ store: Store<GeoTagState, GeoTagEvent>,
                                  extendedTime: Double) -> Task<Void, Never> {
        var locations: [LocationById] = []
        let timeZone = store.timeZone

        for id in store.selection {
            locations.append(LocationById(id: id,
                                          timestamp: store[id]
                                            .metadata
                                            .date(timeZone: timeZone)
                                            .timeIntervalSince1970))
        }
        let task = Task {
            let updatedLocations = await Self.locations(for: locations,
                                                        extendedTime: extendedTime,
                                                        tracks: store.gpxTracks)
            store.send(.locationFromTrack(updatedLocations),
                                          description: "location from tracks")
        }
        return task
    }

    // look up the location for all the LocationById entries passed to
    // the function. The entries are updated when a location within
    // timestamp...timestamp+extendedTime is found.

    static nonisolated func locations(for locations: [LocationById],
                                      extendedTime: Double,
                                      tracks: [GpxTrackLog]) async -> [LocationById] {
        var updatedLocations: [LocationById] = []
        // TODO: max concurrent tasks
        await withTaskGroup { group in
            for ix in locations.indices {
                group.addTask {
                    var found: [(Coords, Double?)] = []

                    // search ALL known tracklogs for the timestamp of the
                    // given image.

                    for track in tracks {
                        if let locn = track.search(imageTime: locations[ix].timestamp,
                                                   extendedTime: extendedTime) {
                            found.append(locn)
                        }
                    }

                    // return the last entry found. If the entry was in multiple
                    // tracklogs the last entry will be the entry closest to
                    // timestamp of the image because the gpxTracks array is
                    // assumed to be sorted by timestamp.

                    return found.last
                }

                for await locn in group {
                    if let locn {
                        updatedLocations.append(
                            LocationById(id: locations[ix].id,
                                         timestamp: locations[ix].timestamp,
                                         coords: locn.0,
                                         elevation: locn.1)
                        )
                    }
                }
            }
        }
        return updatedLocations
    }
}
