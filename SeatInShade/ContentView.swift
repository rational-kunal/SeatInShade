import MapKit
import SwiftUI

struct ContentView: View {
    let mapState: MapState

    var body: some View {
        NavigationView {
            ZStack {
                MapView(mapState: mapState)

                VStack(alignment: .leading) {
                    List {
                        NavigationLink(destination: LocationPicker(forLocation: .From, mapState: mapState)) {
                            Text(mapState.fromLocationTextOrPlaceholder)
                        }
                        NavigationLink(destination: LocationPicker(forLocation: .To, mapState: mapState)) {
                            Text(mapState.toLocationTextOrPlaceholder)
                        }
                    }
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .opacity(0.65)
                }
            }
        }
    }
}

#Preview {
    ContentView(mapState: MapState())
}
