
// MARK: - FoodRescueMapView.swift (TAP-TO-ADD Location)

import SwiftUI
import MapKit
import CoreData

struct FoodRescueMapView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodRescueLocation.timestamp, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<FoodRescueLocation>

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    @State private var selectedMapItem: FoodRescueLocation? // For tapping existing red markers

    // State to store the coordinate of the general map tap
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    // Controls the presentation of the AddLocationView sheet
    @State private var showingAddLocationSheet = false // Renamed for clarity

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapReader { proxy in
                Map(initialPosition: .region(region), selection: $selectedMapItem) {
                    ForEach(locations) { location in
                        Marker(location.name ?? "Location", coordinate: location.coordinate)
                            .tint(.red)
                            .tag(location) // Essential for selection to work
                    }
                    // Removed the temporary blue pin here, as any tap will open AddLocationView
                }
                .onMapCameraChange { context in
                    region = context.region
                }
                .sheet(item: $selectedMapItem) { location in // Sheet for tapping existing red markers
                    LocationDetailView(location: location)
                }
                // --- Gesture for ANY tap on the map background to add new location ---
                .gesture(
                    SpatialTapGesture(coordinateSpace: .local) // Captures tap location relative to the map view
                        .onEnded { value in
                            // Convert screen tap location to map coordinate
                            tappedCoordinate = proxy.convert(value.location, from: .local)
                            // Trigger the AddLocationView sheet
                            showingAddLocationSheet = true
                        }
                )
            } // End MapReader
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
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
        // --- Sheet for adding new location triggered by any map tap ---
        .sheet(isPresented: $showingAddLocationSheet) { // Use the renamed state variable
            AddLocationView(initialCoordinate: tappedCoordinate) // Pass the captured tap coordinate
                .environment(\.managedObjectContext, managedObjectContext)
                .onDisappear { // Clear temporary coordinate when sheet is dismissed
                    tappedCoordinate = nil
                }
        }
    }
}
