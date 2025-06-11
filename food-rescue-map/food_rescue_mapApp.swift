//
//  food_rescue_mapApp.swift
//  food-rescue-map
//
//  Created by Maciek on 11/06/2025.
//

import SwiftUI

@main
struct food_rescue_mapApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
