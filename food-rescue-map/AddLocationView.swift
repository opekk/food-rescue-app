// MARK: - AddLocationView.swift (Updated)

import SwiftUI
import CoreData
import MapKit

struct AddLocationView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss

    // New: Optional initial coordinate
    var initialCoordinate: CLLocationCoordinate2D?

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var details: String = ""
    @State private var contact: String = ""
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.2465, longitude: 22.5684), 
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D? // This will be the coordinate saved
    @State private var showAddressLookupError = false

    var body: some View {
        NavigationView {
            Form {
                Section("Location Information") {
                    TextField("Name of Location (e.g., Food Bank)", text: $name)
                    TextField("Street Address", text: $address)
                    TextField("Contact Info (e.g., email, phone)", text: $contact)
                }

                Section("Details") {
                    TextEditor(text: $details)
                        .frame(height: 100)
                }

                Section("Selected Location on Map") {
                    Map(initialPosition: .region(mapRegion)) {
                        if let selectedCoordinate {
                            Marker("New Location", coordinate: selectedCoordinate)
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(10)
                    .allowsHitTesting(false) // Still non-interactive for simplicity
                }
                
                // Only show geocode button if no initial coordinate was provided
                if initialCoordinate == nil {
                    Button("Geocode Address & Pin on Map") {
                        geocodeAddress()
                    }
                    .disabled(address.isEmpty)
                }
            }
            .navigationTitle("Add New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    // Disable save if required fields are empty or no coordinate is set
                    .disabled(name.isEmpty || address.isEmpty || selectedCoordinate == nil)
                }
            }
            .alert("Address Not Found", isPresented: $showAddressLookupError) {
                Button("OK") { }
            } message: {
                Text("Could not find coordinates for the provided address. Please try a different address or be more specific.")
            }
            .onAppear {
                // If an initial coordinate was passed (from long press), set it and update the map region
                if let initialCoordinate {
                    self.selectedCoordinate = initialCoordinate
                    self.mapRegion = MKCoordinateRegion(
                        center: initialCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
    }

    private func geocodeAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                showAddressLookupError = true
                selectedCoordinate = nil
                return
            }

            if let placemark = placemarks?.first, let location = placemark.location {
                self.selectedCoordinate = location.coordinate
                self.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                showAddressLookupError = false
            } else {
                showAddressLookupError = true
                selectedCoordinate = nil
            }
        }
    }

    private func saveLocation() {
        guard let coordinate = selectedCoordinate else { return }

        let newLocation = FoodRescueLocation(context: managedObjectContext)
        newLocation.id = UUID()
        newLocation.name = name
        newLocation.address = address
        newLocation.latitude = coordinate.latitude
        newLocation.longitude = coordinate.longitude
        newLocation.details = details
        newLocation.contact = contact
        newLocation.timestamp = Date()

        do {
            try managedObjectContext.save()
            dismiss()
        } catch {
            print("Error saving location: \(error)")
        }
    }
}

