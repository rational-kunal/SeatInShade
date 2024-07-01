import CoreLocation
import MapKit
import SwiftAA

struct MapLocation {
    var autoCompletedLocation: MKLocalSearchCompletion?
    var mapItem: MKMapItem?
}

@Observable
class MapState {
    @ObservationIgnored let service = MapService()

    // From
    var fromSearchCompletion: MKLocalSearchCompletion? {
        didSet {
            guard let fromSearchCompletion else { return }
            toSearchCompletion = nil
            toMapItem = nil
            service.mapItem(forSearchCompletion: fromSearchCompletion) { item in
                self.fromMapItem = item
            }
        }
    }

    var fromMapItem: MKMapItem?
    var fromLocationTextOrPlaceholder: String {
        guard let fromSearchCompletion else {
            return "From"
        }

        if fromSearchCompletion.subtitle.count > 0 {
            return "\(fromSearchCompletion.title), \(fromSearchCompletion.subtitle)"
        }
        return "\(fromSearchCompletion.title)"
    }

    // To
    var toSearchCompletion: MKLocalSearchCompletion? {
        didSet {
            guard let toSearchCompletion else { return }
            service.mapItem(forSearchCompletion: toSearchCompletion) { item in
                self.toMapItem = item
            }
        }
    }

    var toMapItem: MKMapItem? {
        didSet {
            guard let fromMapItem, let toMapItem else { return }
            Task {
                do {
                    let (route, expectedTime) = try await service.route(fromMapItem: fromMapItem, toMapItem: toMapItem)
                    self.expectedTime = expectedTime
                    self.route = route
                } catch {
                    print("Error \(error)")
                }
            }
        }
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

    // Route
    var route: MKRoute? {
        didSet {
            guard let route, let expectedTime else { return }

            let firstPoint = route.polyline.points()[0]
            let lastPoint = route.polyline.points()[route.polyline.pointCount - 1]
            let totalDistance = distanceBetween(firstPoint.coordinate, lastPoint.coordinate)
            let noOfSegments = max(totalDistance / 50000, 5)
            let distanceInterval: CLLocationDistance = totalDistance / noOfSegments

            let interpolatedPointsWithSunPosition = interpolatePoints(by: distanceInterval, along: route.polyline, deltaTimeinterval: expectedTime / noOfSegments)

            self.interpolatedPointsWithSunPosition = interpolatedPointsWithSunPosition
        }
    }

    var expectedTime: TimeInterval?

    var interpolatedPointsWithSunPosition: [(coordinate: CLLocationCoordinate2D, sunPosition: HorizontalCoordinates)]?

    var selfBearingDirection: Double? {
        guard let fromMapLocation = fromMapItem?.placemark.location, let toMapLocation = toMapItem?.placemark.location else {
            return nil
        }

        return calculateBearing(from: fromMapLocation.coordinate, to: toMapLocation.coordinate)
    }
}

private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
    let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
    let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
    return loc1.distance(from: loc2)
}

private func interpolatePoints(by distance: CLLocationDistance, along polyline: MKPolyline, deltaTimeinterval: TimeInterval) -> [(coordinate: CLLocationCoordinate2D, sunPosition: HorizontalCoordinates)] {
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

    var afterTimeinterval: TimeInterval = 0
    let interpolatedPointsWithSunPosition: [(CLLocationCoordinate2D, HorizontalCoordinates)] = interpolatedPoints.compactMap { point in
        defer { afterTimeinterval += deltaTimeinterval }
        let sunPosition = calculateSunPosition(forCoordinates: point, afterTimeinterval: afterTimeinterval)
        guard sunPosition.altitude.value >= 0 else {
            return nil
        }
        return (coordinate: point, sunPosition: sunPosition)
    }

    return interpolatedPointsWithSunPosition
}

private func calculateSunPosition(forCoordinates coordinate: CLLocationCoordinate2D, afterTimeinterval: TimeInterval) -> HorizontalCoordinates {
    let observer = GeographicCoordinates(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    let julianDay = JulianDay(Date(timeIntervalSinceNow: afterTimeinterval))
    let sun = Sun(julianDay: julianDay)
    let sunPosition = sun.equatorialCoordinates
    return sunPosition.makeHorizontalCoordinates(for: observer, at: julianDay)
}

func calculateBearing(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
    let lat1 = coordinate1.latitude * .pi / 180.0
    let lon1 = coordinate1.longitude * .pi / 180.0
    let lat2 = coordinate2.latitude * .pi / 180.0
    let lon2 = coordinate2.longitude * .pi / 180.0

    let dLon = lon2 - lon1

    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

    let initialBearing = atan2(y, x)

    // Convert radians to degrees
    var bearing = initialBearing * 180.0 / .pi

    // Normalize to 0-360
    bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)

    return bearing
}
