/**
import CoreLocation
import MapKit
import SwiftAA

class MapStatefulService {
    @ObservationIgnored private let service = MapService()

    private(set) var fromSearchCompletion: MKLocalSearchCompletion?
    private(set) var fromMapItem: MKMapItem?

    private(set) var toSearchCompletion: MKLocalSearchCompletion?
    private(set) var toMapItem: MKMapItem?

    private(set) var route: MKRoute?
    private(set) var expectedTime: TimeInterval?

    private(set) var interpolatedPointsWithSunDirection: [(coordinate: CLLocationCoordinate2D, sunDirectionInDegree: Double, sunIntensity: Double)]?
}

extension MapStatefulService {
    var fromLocationTextOrPlaceholder: String {
        guard let fromSearchCompletion else {
            return "From"
        }

        if fromSearchCompletion.subtitle.count > 0 {
            return "\(fromSearchCompletion.title), \(fromSearchCompletion.subtitle)"
        }
        return "\(fromSearchCompletion.title)"
    }

    var toLocationTextOrPlaceholder: String {
        guard let toSearchCompletion else {
            return "To"
        }

        if toSearchCompletion.subtitle.count > 0 {
            return "\(toSearchCompletion.title), \(toSearchCompletion.subtitle)"
        }
        return "\(toSearchCompletion.title)"
    }
}

extension MapStatefulService {
    func updateFromSearchCompletion(_ fromSearchCompletion: MKLocalSearchCompletion?) {
        self.fromSearchCompletion = fromSearchCompletion

        guard let fromSearchCompletion else { return }
        toSearchCompletion = nil
        toMapItem = nil
        service.mapItem(forSearchCompletion: fromSearchCompletion) { [weak self] mapItem in
            self?.fromMapItem = mapItem
            self?.calculateRouteIfNeeded()
        }
    }

    func updateToSearchCompletion(_ toSearchCompletion: MKLocalSearchCompletion?) {
        self.toSearchCompletion = toSearchCompletion

        guard let toSearchCompletion else { return }
        service.mapItem(forSearchCompletion: toSearchCompletion) { [weak self] mapItem in
            self?.toMapItem = mapItem
            self?.calculateRouteIfNeeded()
        }
    }

    func calculateRouteIfNeeded() {
        guard let fromMapItem, let toMapItem else { return }
        Task {
            do {
                // Calculate route and expected time
                let (route, expectedTime) = try await service.route(fromMapItem: fromMapItem, toMapItem: toMapItem)
                self.route = route
                self.expectedTime = expectedTime

                self.interpolatePointsInNeeded()
            } catch {
                print("Error \(error)")
            }
        }
    }

    private func interpolatePointsInNeeded() {
        guard let route, let expectedTime else { return }

        let polyline = route.polyline
        let firstPoint = polyline.points()[0]
        let lastPoint = polyline.points()[polyline.pointCount - 1]
        let totalDistance = distanceBetween(firstPoint.coordinate, lastPoint.coordinate)
        let distanceInterval: CLLocationDistance = min(1000, totalDistance / 5)

        self.interpolatedPointsWithSunDirection = interpolatePoints(by: distanceInterval, along: polyline, deltaTimeiInterval: expectedTime / (totalDistance / distanceInterval))
    }
}

private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
    let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
    let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
    return loc1.distance(from: loc2)
}

private func interpolatePoints(by distance: CLLocationDistance, along polyline: MKPolyline, deltaTimeiInterval: TimeInterval) -> [(coordinate: CLLocationCoordinate2D, sunDirectionInDegree: Double, sunIntensity: Double)] {
    var interpolatedPoints = [CLLocationCoordinate2D]()
    let coordinates = polyline.points()
    let pointCount = polyline.pointCount

    guard pointCount > 1 else {
        return []
    }

    var accumulatedDistance: CLLocationDistance = 0
    var lastPoint = coordinates[0].coordinate

    interpolatedPoints.append(lastPoint)

    for i in 1 ..< pointCount {
        let currentPoint = coordinates[i].coordinate
        let segmentDistance = distanceBetween(lastPoint, currentPoint)

        accumulatedDistance += segmentDistance

        while accumulatedDistance >= distance {
            let excessDistance = accumulatedDistance - distance
            let interpolationFactor = 1.0 - (excessDistance / segmentDistance)
            let interpolatedLat = lastPoint.latitude + (currentPoint.latitude - lastPoint.latitude) * interpolationFactor
            let interpolatedLon = lastPoint.longitude + (currentPoint.longitude - lastPoint.longitude) * interpolationFactor
            let interpolatedCoordinate = CLLocationCoordinate2D(latitude: interpolatedLat, longitude: interpolatedLon)

            interpolatedPoints.append(interpolatedCoordinate)
            accumulatedDistance -= distance
            lastPoint = interpolatedCoordinate
        }

        lastPoint = currentPoint
    }

    var afterTimeInterval: TimeInterval = 0
    let interpolatedPointsWithSunDirection: [(CLLocationCoordinate2D, Double, Double)] = interpolatedPoints.compactMap { point in
        defer { afterTimeInterval += deltaTimeiInterval }
        let sunPosition = calculateSunPosition(forCoordinates: point, afterTimeinterval: afterTimeInterval)
        guard sunPosition.altitude.value >= 0 else {
            return nil
        }
        return (coordinate: point, sunDirectionInDegree: sunPosition.northBasedAzimuth, sunIntensity: cos(sunPosition.altitude.inRadians.value))
    }

    return interpolatedPointsWithSunDirection
}

private func calculateSunPosition(forCoordinates coordinate: CLLocationCoordinate2D, afterTimeinterval: TimeInterval) -> HorizontalCoordinates {
    let observer = GeographicCoordinates(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    let julianDay = JulianDay(Date(timeIntervalSinceNow: afterTimeinterval))
    let sun = Sun(julianDay: julianDay)
    let sunPosition = sun.equatorialCoordinates
    return sunPosition.makeHorizontalCoordinates(for: observer, at: julianDay)
}
*/
