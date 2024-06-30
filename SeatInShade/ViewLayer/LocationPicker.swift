import SwiftUI

struct LocationPicker: View {
    enum ForLocation { case From, To }

    @Environment(\.dismiss) private var dismiss
    let forLocation: ForLocation
    let mapState: MapState
    let searchCompleterStatefulService = MapSearchCompleterStatefulService()

    @State var searchQuery: String = ""

    var body: some View {
        Form {
            Section("Location Picker") {
                TextField(forLocation == .From ? "From" : "To", text: $searchQuery)
                    .onChange(of: searchQuery) {
                        searchCompleterStatefulService.update(query: searchQuery)
                    }
            }
            Section {
                List {
                    ForEach(searchCompleterStatefulService.searchResults, id: \.self) { result in
                        Text("\(result.title), \(result.subtitle)")
                            .onTapGesture {
                                if forLocation == .From {
                                    mapState.fromSearchCompletion = result
                                } else {
                                    mapState.toSearchCompletion = result
                                }
                                dismiss()
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    LocationPicker(forLocation: .From, mapState: MapState())
}
