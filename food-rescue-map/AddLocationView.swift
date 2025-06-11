// MARK: - AddLocationView.swift (Updated for Reverse Geocoding)

import SwiftUI
import CoreData
import MapKit // Required for CLGeocoder, CLLocationCoordinate2D

struct AddLocationView: View {
    // Environment variables for CoreData context and dismissing the view
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss

    // Optional coordinate passed from the map for pre-filling
    var initialCoordinate: CLLocationCoordinate2D?

    // MARK: - State Variables
    @State private var name: String = ""        // Name of the location
    @State private var address: String = ""     // Street address
    @State private var details: String = ""     // Additional details
    @State private var contact: String = ""     // Contact information

    // Map region, defaults to a specific location (Lublin, Poland)
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.2465, longitude: 22.5684),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // The coordinate chosen for saving (either from initial or geocoded)
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    // Controls display of address lookup error alert
    @State private var showAddressLookupError = false
    // Controls display of reverse geocoding error alert
    @State private var showReverseGeocodeError = false

    // MARK: - Body
    var body: some View {
        NavigationView { // Provides navigation bar for title and buttons
            Form { // Organized input fields
                Section("Location Information") {
                    TextField("Name of Location (e.g., Food Bank)", text: $name)

                    // HStack for address field and reverse geocode button
                    HStack {
                        TextField("Street Address", text: $address) // Street address input

                        // Button to reverse geocode the selected map coordinate
                        if let selectedCoordinate { // Only show if a coordinate is selected
                            Button {
                                reverseGeocodeCoordinate(coordinate: selectedCoordinate)
                            } label: {
                                Image(systemName: "location.magnifyingglass")
                                    .accessibilityLabel("Get address from map pin")
                            }
                            .buttonStyle(.plain) // Use a plain style for just the icon
                        }
                    }
                }
                TextField("Contact Info (e.g., email, phone)", text: $contact)

                Section("Details") {
                    TextEditor(text: $details) // Multiline text input
                        .frame(height: 100)
                }

                Section("Selected Location on Map") {
                    Map(initialPosition: .region(mapRegion)) { // Displays chosen location on a mini-map
                        if let selectedCoordinate {
                            Marker("New Location", coordinate: selectedCoordinate) // Pin for selected coordinate
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(10)
                    .allowsHitTesting(false) // Prevents map interaction (just a visual)
                }
                
                // Show geocode button only if no initial coordinate was provided
                // AND if the address field is empty (to encourage geocoding if starting from address)
                if initialCoordinate == nil && address.isEmpty {
                    Button("Geocode Address & Pin on Map") {
                        geocodeAddress() // Trigger address conversion to coordinates
                    }
                    .disabled(address.isEmpty) // Disable if address is empty
                }
            }
            .navigationTitle("Add New Location") // Title for the navigation bar
            .navigationBarTitleDisplayMode(.inline) // Compact title display
            .toolbar { // Buttons in the navigation bar
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() } // Dismisses the sheet without saving
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveLocation() } // Saves the new location
                    // Disable save if essential fields are empty or no coordinate is set
                    .disabled(name.isEmpty || address.isEmpty || selectedCoordinate == nil)
                }
            }
            .alert("Address Not Found", isPresented: $showAddressLookupError) {
                Button("OK") { }
            } message: {
                Text("Could not find coordinates for the provided address. Please try a different address or be more specific.")
            }
            .alert("Address Lookup Failed", isPresented: $showReverseGeocodeError) {
                Button("OK") { }
            } message: {
                Text("Could not find a street address for the selected location.")
            }
            .onAppear { // Executed when the view appears
                // If a coordinate was passed (from map tap), pre-fill it
                if let initialCoordinate {
                    self.selectedCoordinate = initialCoordinate
                    // Adjust map region to center on the pre-filled coordinate
                    self.mapRegion = MKCoordinateRegion(
                        center: initialCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    // Automatically attempt to reverse geocode if coordinate was passed in
                    reverseGeocodeCoordinate(coordinate: initialCoordinate)
                }
            }
        }
    }

    // MARK: - Private Methods

    // Converts a text address to geographic coordinates
    private func geocodeAddress() {
        let geocoder = CLGeocoder() // Apple's geocoding service
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                showAddressLookupError = true // Show error alert
                selectedCoordinate = nil
                return
            }

            // If successful, get the first placemark's location
            if let placemark = placemarks?.first, let location = placemark.location {
                self.selectedCoordinate = location.coordinate // Set coordinate for saving
                // Update map region to center on the geocoded location
                self.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                showAddressLookupError = false // Clear any previous error
            } else {
                showAddressLookupError = true // No placemark found
                selectedCoordinate = nil
            }
        }
    }

    // Converts geographic coordinates to a human-readable address
    private func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder() // Apple's geocoding service
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                showReverseGeocodeError = true // Show error alert
                return
            }

            // Attempt to construct a full address string
            if let placemark = placemarks?.first {
                // Prioritize common address components
                let addressComponents: [String?] = [
                    placemark.thoroughfare,   // Street name
                    placemark.subThoroughfare, // Street number
                    placemark.locality,       // City
                    placemark.administrativeArea, // State/Province
                    placemark.postalCode,     // Postal Code
                    placemark.country         // Country
                ]

                // Filter out nils and join with commas
                let formattedAddress = addressComponents.compactMap { $0 }.joined(separator: ", ")

                if !formattedAddress.isEmpty {
                    self.address = formattedAddress // Update the address text field
                } else {
                    self.address = "Address not found for this point." // Fallback if no components
                    showReverseGeocodeError = true
                }
            } else {
                self.address = "Address not found." // General fallback
                showReverseGeocodeError = true
            }
        }
    }

    private func saveLocation() {
        guard let coordinate = selectedCoordinate else { return } // Ensure coordinate is set

        // Create a new CoreData object
        let newLocation = FoodRescueLocation(context: managedObjectContext)
        newLocation.id = UUID() // Assign a unique ID
        newLocation.name = name
        newLocation.address = address
        newLocation.latitude = coordinate.latitude
        newLocation.longitude = coordinate.longitude
        newLocation.details = details
        newLocation.contact = contact
        newLocation.timestamp = Date() // Record creation time

        do {
            try managedObjectContext.save() // Save changes to CoreData
            dismiss() // Dismiss the sheet
        } catch {
            print("Error saving location: \(error)") // Log any save errors
        }
    }
}

