//
//  RestaurantFinder.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyXMLParser
import CoreLocation

class RestaurantGuide {
    var restaurants = [Restaurant]()
    
    init() {
    }
    
    func getListOfRestaurants(for location: CLLocation) -> String {
        var restaurantsWithDistance = [(Int, String)]()
        
        for restaurant in restaurants {
            restaurantsWithDistance.append((getDistance(of: restaurant, to: location), restaurant.DisplayString))
        }
        
        restaurantsWithDistance = restaurantsWithDistance.filter() { item in item.0 < 1000 }
        
        restaurantsWithDistance.sort { (first, second) -> Bool in
            return first.0 < second.0
        }
        
        var result = ""
        for (dist, rest) in restaurantsWithDistance {
            result += "\(dist)m\n\(rest)\n\n"
        }
        return result
    }
    
    func getDistance(of restaurant: Restaurant, to location: CLLocation) -> Int {
        let restaurantLocation = CLLocation(latitude: restaurant.latitude as CLLocationDegrees, longitude: restaurant.longitude as CLLocationDegrees)
        return Int(restaurantLocation.distance(from: location))
    }
}

class Restaurant {
    var latitude: Double
    var longitude: Double
    
    var restaurantName: String = "Nameless Restaurant"
    var street: String?
    var houseNumber: String?
    
    init(_ lat: Double, _ lon: Double) {
        self.latitude = lat
        self.longitude = lon
    }
    
    var DisplayString: String
    {
        get {
            var address = ""
            if let street = street {
                address = street
                if let houseNumber = houseNumber {
                    address += " \(houseNumber)"
                }
            } else {
                address = "<address unknown>"
            }
            return "\(restaurantName) \n\(address)"
        }
    }
}

class RestaurantFinder {
    static func updatePosition(_ position: CLLocation, _ onRestaurantsFound: @escaping (RestaurantGuide) -> (), _ onError: @escaping (String) -> ()) {
        
        let downloadDestination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("xapi.xml")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let centerLong = Double(position.coordinate.longitude)
        let centerLat = Double(position.coordinate.latitude)
        let offset = 0.02
        let geoConstraint = "[bbox=\(centerLong - offset),\(centerLat - offset),\(centerLong + offset),\(centerLat + offset)]"
        
        let httpRequest = "https://www.overpass-api.de/api/xapi?node[amenity=restaurant]\(geoConstraint)"

        Alamofire.download(httpRequest, to: downloadDestination).response {
            response -> Void in
            
            if let error = response.error {
                onError(error.localizedDescription)
                return
            }
            
            do {
                let xmlText = try String(contentsOf: response.destinationURL!, encoding: .utf8)
                let xml = try XML.parse(xmlText)
                
                let restaurantGuide = parseXML(xml)
                
                if restaurantGuide.restaurants.count > 0 {
                    onRestaurantsFound(restaurantGuide)
                } else {
                    onError("no Restaurants found")
                }
            }
            catch {
                onError("XML file could not be found/parsed")
                return
            }
        }
    }
    
    static func parseXML(_ xml: XML.Accessor) -> RestaurantGuide {
        let guide = RestaurantGuide()
        for info in xml["osm", "node"] {
            var lat, lon: Double?
            
            for (key, value) in info.attributes {
                if key == "lat" { if let l = Double(value) { lat = l } }
                if key == "lon" { if let l = Double(value) { lon = l } }
            }
            
            guard let latitude = lat, let longitude = lon else {
                continue
            }
            
            let restaurant = Restaurant(latitude, longitude)
            
            for tag in info["tag"] {
                if tag.attributes["k"] == "name" { restaurant.restaurantName = tag.attributes["v"]! }
                if tag.attributes["k"] == "addr:street" { restaurant.street = tag.attributes["v"]! }
                if tag.attributes["k"] == "addr:housenumber" { restaurant.houseNumber = tag.attributes["v"]! }
            }
            
            guide.restaurants.append(restaurant)
        }
        return guide
    }
}
