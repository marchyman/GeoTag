//
//  SearchState.swift
//  SMap
//
//  Created by Marco S Hyman on 3/12/24.
//

import MapKit
import SwiftUI

fileprivate let maxPlaces = 10

// an Observable class to hold map search state

@Observable
final class SearchState {
    var searchResult: SearchPlace?
    var searchPlaces: [SearchPlace] = []
    var searchText: String = ""
    var writing = false

    init() {
        Task {
            searchPlaces = fetchPlaces()
        }
    }
}

// SearchState functions to update the list of visited places and store
// them in the Application Support folder so they won't be lost between
// program runs.

extension SearchState {

    // set the current searchResult and add it to the array of places unless
    // already there.  The array is capped at maxPlaces entries

    func saveResult(_ searchResult: SearchPlace?) {
        self.searchResult = searchResult
        if let searchResult {
            if !searchPlaces.contains(where: { $0.name == searchResult.name }) {
                searchPlaces.append(searchResult)
                if searchPlaces.count > maxPlaces {
                    searchPlaces.removeFirst()
                }
                savePlaces()
            }
        }
    }

    // clear the list of searchPlaces

    func clearPlaces() {
        searchPlaces = []
        savePlaces()
    }

    // return the URL of "Places" in the app support folder

    private func appSupportURL() -> URL {

        let name = "Places"
        let fileManager = FileManager.default
        do {
            let supportDir =
                try fileManager.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
            let placesURL = supportDir.appendingPathComponent(name)
            return placesURL
        } catch {
            fatalError("Can not create application support folder")
        }
    }

    // fetch saved Places from file in application support dir
    // this is only done when the class is initialized

    private func fetchPlaces() -> [SearchPlace] {
        let url = appSupportURL()
        if let places = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode([SearchPlace].self,
                                                 from: places)
                return decoded
            } catch let DecodingError.dataCorrupted(context) {
                print(context)
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch let DecodingError.typeMismatch(type, context) {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
            } catch {
                print("error: ", error)
            }
            fatalError("JSON Decoding Error for \(url)")
        }
        return []
    }

    // Encode and write searchPlaces.  Only one write can be active at a
    // time. Writes while a write is pending will be thrown away.

    private func savePlaces() {
        if !writing {
            writing = true
            Task.detached { [self] in
                let url = appSupportURL()
                do {
                    let encoder = JSONEncoder()
                    let encoded = try encoder.encode(searchPlaces)
                    try encoded.write(to: url)
                    await MainActor.run {
                        writing = false
                    }
                } catch {
                    fatalError("JSON Encoding Error for \(url)")
                }
            }
        }
    }
}

