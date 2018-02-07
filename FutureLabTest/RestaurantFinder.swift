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

class RestaurantsInfo {
    var restaurants = [RestaurantInfo]()
    
    init() {
    }
    
    var DisplayString: String
    {
        get {
            var result = ""
            for rest in restaurants {
                result += rest.DisplayString + "\n"
            }
            return result
        }
    }
}

class RestaurantInfo {
    var name: String = "unknown"
    var street: String = "unknown"
    var number: String = "unknown"
    
    var lat: String?
    var lon: String?
    
    init() {
    }
    
    var DisplayString: String
    {
        get {
            return "\(name) (\(street) \(number))"
        }
    }
}

class RestaurantFinder : NSObject, XMLParserDelegate {
    
    var lastPosition: RestaurantsInfo?
    
    override init() {
        super.init()
    }
    
    func updatePosition(_ position: CLLocation, _ success: @escaping (RestaurantsInfo) -> (), _ fail: () -> ()) {
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("xapi.xml")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let centerLong = position.coordinate.longitude
        let centerLat = position.coordinate.latitude
        
        let lowerLong = Double(centerLong) - 0.01// 8.74477
        let lowerLat = Double(centerLat) - 0.01// 47.4972
        let upperLong = Double(centerLong) + 0.01// 8.75962
        let upperLat = Double(centerLat) + 0.01// 47.50549
        let urlString = "https://www.overpass-api.de/api/xapi?node[amenity=restaurant][bbox=\(lowerLong),\(lowerLat),\(upperLong),\(upperLat)]"

        let allInfos = RestaurantsInfo()
        
        Alamofire.download(urlString, to: destination).response { response in
            let xmlText = try! String(contentsOf: response.destinationURL!, encoding: .utf8)
            let xml = try! XML.parse(xmlText)
            for info in xml["osm", "node"] {
                let restaurant = RestaurantInfo()
                
                for (key, value) in info.attributes {
                    if key == "lat" {
                        restaurant.lat = value
                    }
                    if key == "lon" {
                        restaurant.lon = value
                    }
                }
                for tag in info["tag"] {
                    if tag.attributes["k"] == "name" {
                        restaurant.name = tag.attributes["v"]!
                    }
                    if tag.attributes["k"] == "addr:street" {
                        restaurant.street = tag.attributes["v"]!
                    }
                    if tag.attributes["k"] == "addr:housenumber" {
                        restaurant.number = tag.attributes["v"]!
                    }
                }
                allInfos.restaurants.append(restaurant)
            }
            
            success(allInfos)
        }
    }
}
