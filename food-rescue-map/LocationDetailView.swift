import SwiftUI
import MapKit

struct LocationDetailView: View {
    let location: FoodRescueLocation

    @State private var showCopiedAlert = false

    var body: some View {
        Form {
            Section("Location Info") {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.accentColor)
                    Text(location.name ?? "Unknown Name")
                }
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.accentColor)
                    Text(location.address ?? "No Address Provided")
                }
            }

            Section("Details") {
                Text(location.details ?? "No additional details.")
            }

            Section("Contact") {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.accentColor)

                    Text(location.contact ?? "No Contact Info")
                        .onLongPressGesture {
                            if let phone = location.contact, !phone.isEmpty {
                                UIPasteboard.general.string = phone
                                showCopiedAlert = true
                            }
                        }
                }
            }

            Section("On Map") {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker(location.name ?? "Location", coordinate: location.coordinate)
                }
                .frame(height: 200)
                .cornerRadius(10)
                .allowsHitTesting(false)
            }
        }
        .navigationTitle(location.name ?? "Location Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCopiedAlert) {
            Alert(title: Text("Copied"), message: Text("Phone number copied to clipboard."), dismissButton: .default(Text("OK")))
        }
    }
}
