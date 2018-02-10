//
//  NavigationFlow.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 10.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation

class NavigationFlow {
    
    var isCurrentlyTracking = false
    var navigator = Navigator()
    
    var onStartsTracking: () -> () = { () in }
    var onStopsTracking: () -> () = { () in }
    var onLocationChanged: (CLLocation) -> () = { location in }
    var onHeadingChanged: (CLHeading) -> () = { heading in }
    var onErrorOccurred: (String) -> () = { message in }
    
    init(_ onStartsTracking: @escaping () -> (),
         _ onStopsTracking: @escaping () -> (),
         _ onLocationChanged: @escaping (CLLocation) -> (),
         _ onHeadingChanged: @escaping (CLHeading) -> (),
         _ onErrorOccurred: @escaping (String) -> ()) {
        self.onStartsTracking = onStartsTracking
        self.onStopsTracking = onStopsTracking
        self.onLocationChanged = onLocationChanged
        self.onHeadingChanged = onHeadingChanged
        self.onErrorOccurred = onErrorOccurred
    }
    
    func switchOnOff() {
        if isCurrentlyTracking {
            isCurrentlyTracking = false
            stopTracking()
        } else {
            isCurrentlyTracking = true
            startTracking()
        }
    }
    
    func startTracking() {
        onStartsTracking()
        navigator.startTracking(onLocationChanged, onHeadingChanged, onErrorOccurred)
    }
    
    func stopTracking() {
        navigator.stopTracking()
        onStopsTracking()
    }
}
