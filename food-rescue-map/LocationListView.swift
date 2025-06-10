// MARK: - LocationListView.swift

import SwiftUI
import CoreData

struct LocationListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    // Fetch all FoodRescueLocation objects, sorted by name
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodRescueLocation.name, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<FoodRescueLocation>

    @State private var searchText: String = ""

    // Filtered computed property for search functionality
    var filteredLocations: [FoodRescueLocation] {
        if searchText.isEmpty {
            return Array(locations)
        } else {
            return locations.filter {
                $0.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.address?.localizedCaseInsensitiveContains(searchText) ?? false 
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Display filtered locations
                ForEach(filteredLocations) { location in
                    // NavigationLink to show details when tapped
                    NavigationLink(destination: LocationDetailView(location: location)) {
                        VStack(alignment: .leading) {
                            Text(location.name ?? "Unknown Location")
                                .font(.headline)
                            Text(location.address ?? "No address")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                // Enable swipe-to-delete
                .onDelete(perform: deleteLocation)
            }
            .navigationTitle("Rescue Locations")
            // Search bar for filtering
            .searchable(text: $searchText, prompt: "Search locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton() // Enables reordering and easy deletion
                }
            }
        }
    }

    private func deleteLocation(offsets: IndexSet) {
        withAnimation {
            // Delete objects from CoreData
            offsets.map { filteredLocations[$0] }.forEach(managedObjectContext.delete)

            do {
                try managedObjectContext.save() // Save changes to persistent store
            } catch {
                // Handle the error appropriately
                print("Error deleting location: \(error.localizedDescription)")
            }
        }
    }
}

