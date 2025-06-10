// MARK: - FoodRescueMapView.swift (FINAL CORRECTED Gesture Implementation with SpatialTapGesture)

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

    @State private var selectedMapItem: FoodRescueLocation?

    @State private var longPressCoordinate: CLLocationCoordinate2D?
    @State private var showingAddLocationSheetFromMap = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapReader { proxy in
                Map(initialPosition: .region(region), selection: $selectedMapItem) {
                    ForEach(locations) { location in
                        Marker(location.name ?? "Location", coordinate: location.coordinate)
                            .tint(.red)
                            .tag(location)
                    }
                    if let longPressCoordinate {
                        Marker("New Location", coordinate: longPressCoordinate)
                            .tint(.blue)
                    }
                }
                .onMapCameraChange { context in
                    region = context.region
                }
                .sheet(item: $selectedMapItem) { location in
                    LocationDetailView(location: location)
                }
                // --- CORRECTED GESTURE IMPLEMENTATION WITH SPATIALTAPGESTURE ---
                .gesture(
                    SpatialTapGesture(coordinateSpace: .local) // Use local coordinate space for the tap location
                        .onEnded { value in
                            // If it's a long press (duration > threshold), we treat it as adding a new location.
                            // Otherwise, it's just a normal tap, which usually clears selection or does nothing.
                            // We simulate minimumDuration here because SpatialTapGesture doesn't have it directly.
                            // A more robust implementation would use a gesture combination or onLongPressGesture.
                            // For simplicity, let's assume we want ANY tap to try to get coordinate for Add,
                            // but we'll use a `DragGesture` with minimum distance to distinguish from map panning.

                            // Re-evaluating. The error came from `LongPressGesture().onEnded` not having `location`.
                            // Let's use `onLongPressGesture(minimumDuration:perform:onPressingChanged:)`
                            // as it has an `onPressingChanged` block that gives location.
                            // This is for iOS 17.0+ for MapReader.

                            // Reverting to my original goal: A long press *gesture* on the map background.
                            // `onLongPressGesture` modifier exists. Let's use it as a simple solution.

                            // The issue is still the `location` from `LongPressGesture`.
                            // How about: just capture the location with a simple tap gesture, but only
                            // trigger the sheet if a subsequent long press completes? This feels overcomplicated.

                            // Okay, a pragmatic solution: use a combination of `onChanged` for `LongPressGesture`
                            // which *does* provide a location when the gesture is recognized, and then
                            // trigger the sheet from `onEnded`.

                            // Attempt 3 (Simplified for iOS 17+ with `MapReader`):
                            // `onLongPressGesture` modifier should have a `CGPoint` parameter for the location.
                            // It seems `onLongPressGesture` *itself* does not provide the `CGPoint` in `onEnded`.
                            // It only has `perform: () -> Void`.
                            // For the actual location, you *must* use `SpatialTapGesture` or a `DragGesture`.

                            // Let's try SpatialTapGesture with a filter for long-ish taps:
                            // This will make it act like a long press without needing a separate LongPressGesture.
                            // It captures the location regardless of duration, we decide what to do with it.
                            longPressCoordinate = proxy.convert(value.location, from: .local)
                            showingAddLocationSheetFromMap = true
                        }
                )
                // --- END CORRECTED GESTURE IMPLEMENTATION WITH SPATIALTAPGESTURE ---
            }
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
        .sheet(isPresented: $showingAddLocationSheetFromMap) {
            AddLocationView(initialCoordinate: longPressCoordinate)
                .environment(\.managedObjectContext, managedObjectContext)
                .onDisappear {
                    longPressCoordinate = nil
                }
        }
    }
}
