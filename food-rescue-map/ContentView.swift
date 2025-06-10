import SwiftUI

struct ContentView: View {
    @State private var showingAddLocationSheet = false
    @State private var titleColor: Color = .primary

    var body: some View {
        TabView {
            // MARK: - Map Tab
            NavigationView {
                FoodRescueMapView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        // Własny tytuł z gestem
                        ToolbarItem(placement: .principal) {
                            Text("Food Rescue Map")
                                .foregroundColor(titleColor)
                                .font(.headline)
                                .onLongPressGesture {
                                    withAnimation {
                                        titleColor = titleColor == .primary ? .green : .primary
                                    }
                                }
                        }

                        // Przycisk dodawania
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingAddLocationSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            // MARK: - List Tab
            LocationListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet.rectangle.fill")
                }
        }
        .sheet(isPresented: $showingAddLocationSheet) {
            AddLocationView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

