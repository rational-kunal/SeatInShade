import MapKit
import SwiftUI

let MimnimumZoomDistance = 1000.0

struct MapView: View {
    let mapState: MapState

    var body: some View {
        Map(bounds: MapCameraBounds(minimumDistance: MimnimumZoomDistance)) {
            if let fromMapItem = mapState.fromMapItem {
                Marker(item: fromMapItem)
            }
            if let toMapItem = mapState.toMapItem {
                Marker(item: toMapItem)
            }
            if let route = mapState.route {
                MapPolyline(route.polyline)
                    .stroke(.gray, lineWidth: 2.5)
            }
            if let selfBearingDirection = mapState.selfBearingDirection,
               let selfCoordinate = mapState.fromMapItem?.placemark.coordinate
            {
                Annotation("", coordinate: selfCoordinate) {
                    Arrow()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 10, height: 80)
                        .rotationEffect(Angle(degrees: selfBearingDirection))
                }
            }
            if let interpolatedPointsWithSunPosition = mapState.interpolatedPointsWithSunPosition {
                ForEach(interpolatedPointsWithSunPosition, id: \.self.coordinate.latitude) { coordinate, sunPosition in
                    Annotation("", coordinate: coordinate) {
                        Arrow()
                            .stroke(Color.orange, lineWidth: 2)
                            .frame(width: 10, height: 10 + 40 * CGFloat(cos(sunPosition.altitude.inRadians.value)))
                            .rotationEffect(Angle(degrees: sunPosition.northBasedAzimuth.value))
                    }
                }
            }
        }
    }
}

#Preview {
    MapView(mapState: MapState())
}
