import MapKit

class MapService {
    func mapItem(forSearchCompletion: MKLocalSearchCompletion, completion: @escaping (MKMapItem?) -> Void) {
        let locationSearchRequest = MKLocalSearch.Request(completion: forSearchCompletion)
        let search = MKLocalSearch(request: locationSearchRequest)
        search.start { response, error in
            if let error = error {
                print("Error occurred in mapItem search: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(response?.mapItems.first)
            }
        }
    }

    func route(fromMapItem: MKMapItem, toMapItem: MKMapItem, completionRoute: @escaping (MKRoute?) -> Void, completionETA: @escaping (TimeInterval?) -> Void) {
        let request = MKDirections.Request()
        request.source = fromMapItem
        request.destination = toMapItem

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error {
                print("Error occurred in route search: \(error.localizedDescription)")
                completionRoute(nil)
            } else {
                completionRoute(response?.routes.first)
            }
        }
        directions.calculateETA { response, error in
            if let error {
                print("Error occurred in route ETA search: \(error.localizedDescription)")
                completionETA(nil)
            } else {
                completionETA(response?.expectedTravelTime)
            }
        }
    }

    func route(fromMapItem: MKMapItem, toMapItem: MKMapItem, completion: @escaping (MKRoute, TimeInterval) -> Void) {
        let request = MKDirections.Request()
        request.source = fromMapItem
        request.destination = toMapItem

        var route: MKRoute?
        var expectedTime: TimeInterval?
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error {
                print("Error occurred in route search: \(error.localizedDescription)")
            }
            route = response?.routes.first

            if let route, let expectedTime {
                completion(route, expectedTime)
            }
        }
        directions.calculateETA { response, error in
            if let error {
                print("Error occurred in route ETA search: \(error.localizedDescription)")
            }
            expectedTime = response?.expectedTravelTime

            if let route, let expectedTime {
                completion(route, expectedTime)
            }
        }
    }

    func route(fromMapItem: MKMapItem, toMapItem: MKMapItem) async throws -> (MKRoute, TimeInterval) {
        let request = MKDirections.Request()
        request.source = fromMapItem
        request.destination = toMapItem

        let directions = MKDirections(request: request)
        
        @Sendable func calculateRoute() async throws -> MKRoute {
            return try await withCheckedThrowingContinuation { continuation in
                directions.calculate { response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let route = response?.routes.first {
                        continuation.resume(returning: route)
                    } else {
                        continuation.resume(throwing: NSError(domain: "com.example.MyApp", code: -1, userInfo: [NSLocalizedDescriptionKey: "No routes found"]))
                    }
                }
            }
        }

        @Sendable func calculateETA() async throws -> TimeInterval {
            return try await withCheckedThrowingContinuation { continuation in
                directions.calculateETA { response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let expectedTime = response?.expectedTravelTime {
                        continuation.resume(returning: expectedTime)
                    } else {
                        continuation.resume(throwing: NSError(domain: "com.example.MyApp", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ETA found"]))
                    }
                }
            }
        }
        
        let route = try await calculateRoute()
        let expectedTime = try await calculateETA()
        
        return (route, expectedTime)
    }

}
