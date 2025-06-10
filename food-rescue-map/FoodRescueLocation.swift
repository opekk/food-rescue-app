// MARK: - FoodRescueLocation.swift

import Foundation
import CoreData
import CoreLocation // For CLLocationCoordinate2D
import MapKit     // For MKAnnotation

// @objc(FoodRescueLocation) is ESSENTIAL when Codegen is Manual/None.
// It maps this Swift class directly to the "FoodRescueLocation" entity in your .xcdatamodeld.
@objc(FoodRescueLocation)
public class FoodRescueLocation: NSManagedObject, Identifiable {

    // MARK: - Core Data Attributes (Must match your .xcdatamodeld attributes exactly)
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var details: String?
    @NSManaged public var contact: String?
    @NSManaged public var timestamp: Date?

    // MARK: - MKAnnotation Conformance
    // This allows FoodRescueLocation instances to be used directly as map annotations in MapKit.
    public var coordinate: CLLocationCoordinate2D {
        // Ensure latitude and longitude attributes exist and are correct Doubles
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var title: String? {
        // Use the name attribute as the marker's title
        name
    }

    public var subtitle: String? {
        // Use the address attribute as the marker's subtitle
        address
    }
}
