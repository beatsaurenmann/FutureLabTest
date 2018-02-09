//
//  Positioner.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocation {
    var DisplayString: String { get { return "lat=\(String(format: "%.7f", coordinate.latitude)), long=\(String(format: "%.7f", coordinate.longitude))" } }
}

class Positioner : NSObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var isTracking = false
    
    var onLocationChanged: (CLLocation) -> () = { location in }
    var onHeadingChanged: (CLHeading) -> () = { heading in }
    var onErrorOccurred: (String) -> () = { message in }
    
    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking(_ success: @escaping (CLLocation) -> (), _ heading: @escaping (CLHeading) -> (), _ fail: @escaping (String) -> ()) {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        onLocationChanged = success
        onErrorOccurred = fail
        onHeadingChanged = heading
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        onLocationChanged(latestLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        onHeadingChanged(newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
