//
//  LocationManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 29.08.2024.
//

import Foundation
import CoreLocation


class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var completion: ((Result<[String: Double], Error>) -> Void)?
    
    static let shared = LocationManager()  // Singleton instance
    
    private override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }

    // Request location with a completion handler
    func requestLocation(completion: @escaping (Result<[String: Double], Error>) -> Void) {
        self.completion = completion
        
        // Check if location services are enabled
        let myQueue = DispatchQueue(label:"locationQueue")
        myQueue.async {
            guard CLLocationManager.locationServicesEnabled() else {
                completion(.failure(NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location services are not enabled."])))
                return
            }
        }
        // Start updating location directly
        locationManager?.requestLocation()
    }

    // Handle successful location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            self.completion?(.failure(NSError(domain: "LocationError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve location."])))
            self.completion = nil
            return
        }

        // Get latitude and longitude
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Create dictionary and store in UserDefaults
        let locationDict: [String: Double] = ["latitude": latitude, "longitude": longitude]
        let encoder = JSONEncoder()
        if let encodedLocation = try? encoder.encode(locationDict) {
            UserDefaults.standard.set(encodedLocation, forKey: "lastLocation")
        }

        // Call the completion handler with the result
        self.completion?(.success(locationDict))
        self.completion = nil // Clear the completion handler to avoid duplicate calls
    }

    // Handle location update errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        self.completion?(.failure(error))
        self.completion = nil // Clear the completion handler to avoid duplicate calls
    }

    // Handle authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Authorized, nothing to do
            break
        case .denied, .restricted:
            // Access denied, handle appropriately
            self.completion?(.failure(NSError(domain: "LocationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location access denied."])))
            self.completion = nil
        default:
            break
        }
    }
}
