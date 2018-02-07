//
//  AddressFinder.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import Nominatim
import CoreLocation

class Address {
    var country: String?
    var city: String?
    var road: String?
    var number: String?
    
    init() {
    }
    
    var DisplayString: String
    {
        get {
            if let no = number {
                return "\(road!) \(no), \(city!), \(country!)"
            }
            return "\(road!), \(city!), \(country!)"
        }
    }
}

class AddressFinder {
    
    init() {
        
    }
    
    func updatePosition(_ position: CLLocation, _ success: @escaping (Address) -> (), _ fail: @escaping () -> ()) {
        
        Nominatim.getLocation(fromLatitude: String(position.coordinate.latitude), longitude: String(position.coordinate.longitude), completion: {(error, location) -> Void in
            
            if error != nil {
                fail()
            }
            
            if location != nil {
                var address = Address()
                address.country = location!.country
                address.city = location!.city
                address.road = location!.road
                address.number = location!.houseNumber
                
                success(address)
                
            } else {
                fail()
            }
        })
    }
}
