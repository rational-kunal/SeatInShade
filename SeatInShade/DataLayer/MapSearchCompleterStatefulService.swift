//
//  MapSearchCompleterStatefulService.swift
//  ShadeSeat
//
//  Created by Kunal Kamble on 22/06/24.
//

import MapKit

@Observable class MapSearchCompleterStatefulService: NSObject, MKLocalSearchCompleterDelegate {
    var searchResults: [MKLocalSearchCompletion] = []

    @ObservationIgnored
    private lazy var localSearchCompleter: MKLocalSearchCompleter = {
        let searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
        return searchCompleter
    }()

    func update(query: String) {
        localSearchCompleter.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        searchResults = []
    }
}
