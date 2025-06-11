// MARK: - LocationDetailView.swift (Updated with concise comments)

import SwiftUI
import MapKit // Required for Map view and MKCoordinateRegion

struct LocationDetailView: View {
    // The specific FoodRescueLocation object to display
    let location: FoodRescueLocation

    // State to control the visibility of the "Copied" alert
    @State private var showCopiedAlert = false

    // MARK: - Body
    var body: some View {
        Form { // Provides a structured, scrolling list of sections
            Section("Location Info") {
                HStack { // Displays icon and name horizontally
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.accentColor)
                    Text(location.name ?? "Unknown Name")
                }
                HStack { // Displays icon and address horizontally
                    Image(systemName: "map.fill")
                        .foregroundColor(.accentColor)
                    Text(location.address ?? "No Address Provided")
                }
            }

            Section("Details") {
                Text(location.details ?? "No additional details.") // Displays general notes
            }

            Section("Contact") {
                HStack { // Displays icon and contact info horizontally
                    Image(systemName: "phone.fill")
                        .foregroundColor(.accentColor)

                    Text(location.contact ?? "No Contact Info")
                        .onLongPressGesture { // New: Gesture to copy contact info
                            if let contactInfo = location.contact, !contactInfo.isEmpty {
                                UIPasteboard.general.string = contactInfo // Copies text to clipboard
                                showCopiedAlert = true // Triggers the "Copied" alert
                            }
                        }
                }
            }

            Section("On Map") {
                Map(initialPosition: .region(MKCoordinateRegion( // Small, static map preview
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker(location.name ?? "Location", coordinate: location.coordinate) // Pin on the mini-map
                }
                .frame(height: 200) // Fixed height for the map snippet
                .cornerRadius(10)    // Rounded corners for aesthetics
                .allowsHitTesting(false) // Prevents interaction with the mini-map
            }
        }
        .navigationTitle(location.name ?? "Location Details") // Title for the navigation bar
        .navigationBarTitleDisplayMode(.inline) // Compact title display
        .alert(isPresented: $showCopiedAlert) { // Alert presented when showCopiedAlert is true
            Alert(title: Text("Copied"), message: Text("Contact information copied to clipboard."), dismissButton: .default(Text("OK")))
        }
    }
}

