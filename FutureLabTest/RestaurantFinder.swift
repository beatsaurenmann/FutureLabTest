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
    
    private let maximalDistance = 1000
    
    init() {
    }
    
    var restaurants = Set<Restaurant>()
    
    var restaurantsWithinReach = [(Int, Restaurant)]()
    
    var userLocation: CLLocation? {
        didSet {
            guard let newLocation = userLocation else {
                return
            }
            
            restaurantsWithinReach.removeAll()
            for restaurant in restaurants {
                let distance = getDistance(of: restaurant, to: newLocation)
                if distance <= maximalDistance {
                    restaurantsWithinReach.append((distance, restaurant))
                }
            }
            restaurantsWithinReach.sort { (first, second) -> Bool in
                return first.0 < second.0
            }
        }
    }
    
    private func getDistance(of restaurant: Restaurant, to location: CLLocation) -> Int {
        return Int(restaurant.location.distance(from: location))
    }
}

class Restaurant : Hashable {
    
    var id: Int
    var latitude: Double
    var longitude: Double
    
    var restaurantName: String = "<no name available>"
    
    var attributes = [(String, String)]()
    
    init(_ id: Int, _ lat: Double, _ lon: Double) {
        self.id = id
        self.latitude = lat
        self.longitude = lon
    }
    
    static func ==(left: Restaurant, right: Restaurant) -> Bool {
        return left.id == right.id
    }
    
    var hashValue: Int { get { return id } }
    
    var location: CLLocation {
        get {
            return CLLocation(latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees)
        }
    }
    
    var Address: String
    {
        get {
            return "<address unknown>"
        }
    }
    
    var DisplayString: String
    {
        get {
            return "\(restaurantName) \n\(Address)"
        }
    }
}

class RestaurantFinder {
    static func updatePosition(_ position: CLLocation, _ onRestaurantsFound: @escaping ([Restaurant]) -> (), _ onError: @escaping (String) -> ()) {
        
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
                
                let restaurants = parseXML(xml)
                
                if restaurants.count > 0 {
                    onRestaurantsFound(restaurants)
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
    
    static func parseXML(_ xml: XML.Accessor) -> [Restaurant] {
        var restaurants = [Restaurant]()
        for info in xml["osm", "node"] {
            var id: Int?
            var lat, lon: Double?
            
            for (key, value) in info.attributes {
                if key == "id" { if let l = Int(value) { id = l } }
                if key == "lat" { if let l = Double(value) { lat = l } }
                if key == "lon" { if let l = Double(value) { lon = l } }
            }
            
            guard let objectId = id, let latitude = lat, let longitude = lon else {
                continue
            }
            
            let restaurant = Restaurant(objectId, latitude, longitude)
            
            for tag in info["tag"] {
                if tag.attributes["k"] == "name" {
                    restaurant.restaurantName = tag.attributes["v"]!
                } else {
                    guard let key = tag.attributes["k"], let value = tag.attributes["v"] else {
                        continue
                    }
                    restaurant.attributes.append((key, value))
                }
            }
            
            restaurants.append(restaurant)
        }
        return restaurants
    }
}
