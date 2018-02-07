//
//  Positioner.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation

class Position {
    var latitude: String?
    var longitude: String?
    var horizontalAccuracy: String?
    var altitude: String?
    var verticalAccuracy: String?
    
    init() {
    }
    
    var DisplayString: String { get { return "lat=\(latitude!), long=\(longitude!)" } }
}

class Positioner : NSObject, CLLocationManagerDelegate {
    
    
    var lastPosition: Position?
    
    
    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    
    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        startLocation = nil
    }
    
    func updatePosition(_ success: (Position) -> (), _ fail: () -> ()) {
//        lastPosition = getCurrentPosition()
        
        sleep(3)
        
        if let position = lastPosition {
            success(position)
        } else {
            fail()
        }
    }
    
    
//    func getCurrentPosition() -> Position? {
//        return Position()
//    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        var pos = Position()
        pos.latitude = String(format: "%.4f", latestLocation.coordinate.latitude)
        pos.longitude = String(format: "%.4f", latestLocation.coordinate.longitude)
        pos.horizontalAccuracy = String(format: "%.4f", latestLocation.horizontalAccuracy)
        pos.altitude = String(format: "%.4f", latestLocation.altitude)
        pos.verticalAccuracy = String(format: "%.4f", latestLocation.verticalAccuracy)
        
        lastPosition = pos
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let distanceBetween: CLLocationDistance =
            latestLocation.distance(from: startLocation)
        
        //        distance.text = String(format: "%.2f", distanceBetween)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastPosition = nil
    }
    
}
