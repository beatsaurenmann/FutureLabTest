//
//  Navigator.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

extension CLLocation {
    var DisplayString: String { get { return "lat=\(String(format: "%.7f", coordinate.latitude)), long=\(String(format: "%.7f", coordinate.longitude))" } }
}

class Navigator : NSObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
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
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
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
        onErrorOccurred(error.localizedDescription)
    }
}

public extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {

        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians

        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }

    func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

private extension Double {
    var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
    var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
}

