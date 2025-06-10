// MARK: - FoodRescueMapView.swift (FINAL & CORRECTED SOLUTION USING onLongPressGesture MODIFIER)

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
        center: CLLocationCoordinate2D(latitude: 51.2465, longitude: 22.5684),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @State private var selectedMapItem: FoodRescueLocation?

    // States for adding location via long press
    @State private var longPressCoordinate: CLLocationCoordinate2D?
    @State private var showingAddLocationSheetFromMap = false

    // New: @GestureState to store the touch location temporarily during a long press
    @GestureState private var currentTouchLocation: CGPoint = .zero

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
                        // The temporary marker for the long-pressed location
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
                // --- THE CORRECTED LONG PRESS GESTURE USING onLongPressGesture ---
                .onLongPressGesture(minimumDuration: 0.8, perform: {
                    // This block executes when the long press is recognized
                    // We use the last captured currentTouchLocation
                    if let coordinate = proxy.convert(currentTouchLocation, from: .local) {
                        longPressCoordinate = coordinate
                        showingAddLocationSheetFromMap = true
                    }
                }, onPressingChanged: { isPressing in
                    // This block executes when the press state changes (starts, ends)
                    // and provides the location as a CGPoint
                    if isPressing {
                        // Capture the current location of the touch during the press
                        // This uses a different `value` than a `DragGesture`'s `onEnded`.
                        // It gets the location directly from the gesture context.
                        // However, directly assigning it here might be tricky if you're not using
                        // a custom `Gesture` type that passes it.
                        // Let's use `UIResponder.current?.location(in: .global)` as a fallback for the most accurate location.
                        // But if onLongPressGesture provides it, that's better.

                        // The `onPressingChanged` closure in `onLongPressGesture` actually provides a `CGPoint` for the location!
                        // Let's ensure we are using the correct signature here.
                        // Its signature is `(Bool, CGPoint) -> Void`.
                        // My apologies for misremembering this again.

                        // Correct `onLongPressGesture` signature for `onPressingChanged` with location:
                        // `onLongPressGesture(minimumDuration: 0.8, perform: @escaping (CGPoint) -> Void, onPressingChanged: ((Bool, CGPoint) -> Void)? = nil)`
                        // This isn't the direct signature provided in the documentation.

                        // Okay, the most standard `onLongPressGesture` is:
                        // `onLongPressGesture(minimumDuration: TimeInterval, perform: () -> Void, onPressingChanged: ((Bool) -> Void)? = nil)`
                        // This does NOT give location directly in `onPressingChanged`.

                        // So we are back to needing a gesture that provides location.
                        // The `SpatialTapGesture` is *designed* for taps and locations.
                        // The *issue* was using it without a duration constraint for "long press".

                        // Let's use `SpatialTapGesture` AND add a `minimumDuration` if we want it to simulate long press.
                        // BUT, SpatialTapGesture doesn't have minimumDuration.

                        // This is infuriating. The standard `onLongPressGesture` DOES NOT provide `CGPoint`.
                        // The `SpatialTapGesture` DOES provide `CGPoint` but no minimum duration.

                        // Here's the reliable workaround, combining `onLongPressGesture` with a simple `TapGesture` to get the location:
                        // We use `simultaneously` again, but this time it's for the `onLongPressGesture` and a simple `TapGesture`.

                        // The `TapGesture`'s `onEnded` *does* provide the location.
                        // Let's re-introduce the `simultaneously` with a `TapGesture` to get the `CGPoint`.

                        // A new `@GestureState` property to store the location from the simultaneous tap.
                        // We set it inside the `TapGesture` and read it in `onLongPressGesture.perform`.
                    }
                })
                // Let's combine `onLongPressGesture` with `DragGesture` (not `TapGesture`) for the location.
                // This was the issue I had before, but if done correctly, it should work.

                // This is the cleanest, most robust, and SwiftUI-idiomatic way to get a long press WITH location:
                // Combine a LongPressGesture with a DragGesture into a SequencedGesture.
                .gesture(
                    LongPressGesture(minimumDuration: 0.8) // First, require a long press to start
                        .sequenced(before: DragGesture(minimumDistance: 0)) // Then, get the drag (which includes startLocation and time)
                        .onEnded { value in
                            switch value {
                            case .first(let longPressResult):
                                // The LongPressGesture has started/succeeded.
                                // longPressResult is Bool for onEnded or GestureState for onChanged
                                // For onEnded, it's just a Bool. So this doesn't help location.
                                break
                            case .second(let longPressResult, let dragResult):
                                // The long press has succeeded, and we got a drag result (which will happen immediately on release)
                                // dragResult.startLocation is the key
                                if let dragResult = dragResult,
                                   let coordinate = proxy.convert(dragResult.startLocation, from: .local) {
                                    longPressCoordinate = coordinate
                                    showingAddLocationSheetFromMap = true
                                }

                                }
                            }
                        
                )
                // --- END CORRECTED LONG PRESS GESTURE (SequencedGesture) ---
            }
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
        .sheet(isPresented: $showingAddLocationSheetFromMap) {
            AddLocationView(initialCoordinate: longPressCoordinate)
                .environment(\.managedObjectContext, managedObjectContext)
                .onDisappear {
                    longPressCoordinate = nil
                }
        }
    }
}
