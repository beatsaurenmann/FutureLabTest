//
//  RestaurantsFlow.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 10.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation

class RestaurantsFlow {
    let minimalWaitingTimeBetweenTwoRequests: Double = 10
    let minimalCoveredDistanceBetweenTwoRequests: Double = 100
    
    var latestLocation: CLLocation?
    var latestRequest: Date?
    
    var nextLocation: CLLocation?
    
    var onRequestStarted: () -> ()
    var onRestaurantsFound: ([Restaurant]) -> ()
    var onErrorOccurred: (String) -> ()
    
    init(_ onRequestStarted: @escaping () -> (),
         _ onRestaurantsFound: @escaping ([Restaurant]) -> (),
         _ onErrorOccurred: @escaping (String) -> ()) {
        self.onRequestStarted = onRequestStarted
        self.onRestaurantsFound = onRestaurantsFound
        self.onErrorOccurred = onErrorOccurred
    }
    
    func set(newLocation: CLLocation) {
        if nextLocation != nil {
            nextLocation = newLocation
            return
        }
        
        if let latestLocation = latestLocation {
            if newLocation.distance(from: latestLocation) < minimalCoveredDistanceBetweenTwoRequests {
                return
            }
        }
        
        var elapsed: Double = minimalWaitingTimeBetweenTwoRequests
        if let latestRequest = latestRequest {
            elapsed = Date().timeIntervalSince(latestRequest)
        }
        
        nextLocation = newLocation
        DispatchQueue.main.asyncAfter(deadline: .now() + minimalWaitingTimeBetweenTwoRequests-elapsed) {
            self.updateRestaurants()
        }
    }
    
    private func updateRestaurants() {
        guard let nextLocation = nextLocation else { return }
        self.nextLocation = nil
        
        DispatchQueue.global(qos: .default).async {
            self.onRequestStarted()
            self.latestRequest = Date()
            self.latestLocation = nextLocation
            RestaurantFinder.updatePosition(nextLocation, self.onRestaurantsFound, self.onErrorOccurred)
        }
    }
}
