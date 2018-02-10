//
//  AddressFlow.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 10.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation
import Nominatim

class AddressFlow {
    let minimalWaitingTimeBetweenTwoRequests: Double = 5
    let minimalCoveredDistanceBetweenTwoRequests: Double = 5
    
    var latestLocation: CLLocation?
    var latestRequest: Date?
    
    var nextLocation: CLLocation?
    
    var onRequestStarted: () -> ()
    var onAddressUpdated: (Location) -> ()
    var onErrorOccurred: (String) -> ()
    
    init(_ onRequestStarted: @escaping () -> (),
         _ onAddressUpdated: @escaping (Location) -> (),
         _ onErrorOccurred: @escaping (String) -> ()) {
        self.onRequestStarted = onRequestStarted
        self.onAddressUpdated = onAddressUpdated
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
            self.updateAddress()
        }
    }
    
    private func updateAddress() {
        guard let nextLocation = nextLocation else { return }
        self.nextLocation = nil
        
        DispatchQueue.global(qos: .default).async {
            self.onRequestStarted()
            self.latestRequest = Date()
            self.latestLocation = nextLocation
            AddressFinder.findAddress(nextLocation, self.onAddressUpdated, self.onErrorOccurred)
        }
    }
}
