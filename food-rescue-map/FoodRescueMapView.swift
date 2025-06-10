// MARK: - FoodRescueMapView.swift

import SwiftUI
import MapKit
import CoreData

struct FoodRescueMapView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    // Fetch all FoodRescueLocation objects, sorted by timestamp (creation date)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodRescueLocation.timestamp, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<FoodRescueLocation>

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.2465, longitude: 22.5684),// Default to Los Angeles
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    // State to hold the selected location for the detail sheet
    @State private var selectedLocation: FoodRescueLocation?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(initialPosition: .region(region)) {
                // Iterate through all fetched locations and place a Marker for each
                ForEach(locations) { location in
                    Marker(location.name ?? "Location", coordinate: location.coordinate)
                        .tint(.red) // Custom marker color
                        .tag(location) // Assign a tag for selection (though not used directly here)
                }
            }
            // .onMapCameraChange is great for updating a 'region' state if map moves
            .onMapCameraChange { context in
                region = context.region
            }
            // When a Marker is tapped, it can automatically update selectedLocation if using Map(selection:)
            // For this example, we'll open the detail sheet when selectedLocation becomes non-nil
            .sheet(item: $selectedLocation) { location in
                LocationDetailView(location: location)
            }

            // Add a button to recenter the map to a default view (or user's location)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 51.2465, longitude: 22.5684),
                                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                            )
                        }
                    } label: {
                        Image(systemName: "location.circle.fill")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

