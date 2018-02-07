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

extension Location {
    var DisplayString: String
    {
        get {
            var result = ""
            
            if let road = road {
                result += road
            } else {
                result += "<unknown road>"
            }
            
            if let houseNumber = houseNumber {
                result += " \(houseNumber)"
            }
            
            result += ", "
            
            if let city = city {
                result += city
            } else {
                result += "<unknown city>"
            }
            
            if let country = country {
                result += " \(country)"
            } else {
                result += " <unknown country"
            }
            
            return result
        }
    }
}

class AddressFinder {    
    static func findAddress(_ gpsLocation: CLLocation, _ onLocationFound: @escaping (Location) -> (), _ onError: @escaping (String) -> ()) {
        
        Nominatim.getLocation(fromLatitude: String(gpsLocation.coordinate.latitude), longitude: String(gpsLocation.coordinate.longitude)) {
            (error, location) -> Void in
            
            if let error = error {
                onError(error.localizedDescription)
            }
            
            if let loc = location {
                onLocationFound(loc)
            } else {
                onError("no location could be found")
            }
        }
    }
}
