//
//  AppFlow.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 10.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation
import CoreLocation
import Nominatim

class AppFlow {
    
    private let viewController: ViewController
    private let tableController: RestaurantTableViewController
    
    private var navigationFlow: NavigationFlow!
    private var addressFlow: AddressFlow!
    private var restaurantsFlow: RestaurantsFlow!
    
    var userLocation: CLLocation?
    
    var collection = RestaurantCollection()
    var guide = RestaurantGuide()
    
    init(_ viewController: ViewController, _ tableController: RestaurantTableViewController) {
        self.viewController = viewController
        self.tableController = tableController
        
        navigationFlow = NavigationFlow(
            viewController.setControlsToTrackingStarted,
            viewController.setControlsToTrackingEnded,
            onLocationChanged,
            tableController.udpateCompasses,
            viewController.showNavigationError)
        addressFlow = AddressFlow(
            viewController.setControlsToAddressRequestStarted,
            viewController.showAddress,
            viewController.showAddressError)
        restaurantsFlow = RestaurantsFlow(
            viewController.setControlsToRestaurantRequestStarted,
            onRestaurantsFound,
            viewController.showRestaurantError)
    }
    
    func onStartStopPressed() {
        navigationFlow.switchOnOff()
    }
    
    func onLocationChanged(_ newLocation: CLLocation) {
        userLocation = newLocation
        addressFlow.set(newLocation: newLocation)
        restaurantsFlow.set(newLocation: newLocation)
        
        viewController.updateLocationLabel(newLocation)
        updateRestaurantList(newLocation)
    }
    
    var currentRestaurants = [Restaurant]()
    
    func onRestaurantsFound(_ newRestaurants: [Restaurant]) {
        collection.extend(with: newRestaurants)
        
//        let arrayToDist = Array(collection.restaurants).toDictionary() { $0.location.distance(from: userLocation!) }
//        let restaurantsWithinReach = collection.restaurants.filter() { arrayToDist[$0]! < Double(1000) }
//        let sortedRestaurants = restaurantsWithinReach.sorted() { arrayToDist[$0]! < arrayToDist[$1]! }
//
//
//
//
//
//        currentRestaurants = sortedRestaurants
//
//
//
//
//
        let (toBeRemoved, toBeAdded) = guide.update(collection, userLocation!)
//
//        for rest in toBeRemoved {
//            tableController.removeRestaurantAtIndex()
//        }
//
//        for rest in toBeAdded {
//            tableController.removeRestaurantAtIndex()
//        }
        
//        tableController.sort
        
        
        
        
        
        
        
        viewController.setControlsToRestaurantRequestEnded()
        tableController.update(guide.currentRestaurants, toBeAdded, toBeRemoved)
    }
    
    func updateRestaurantList(_ newLocation: CLLocation) {
        tableController.updateDistances(newLocation)
    }
}

class RestaurantWithDistance: Hashable {
    static func ==(lhs: RestaurantWithDistance, rhs: RestaurantWithDistance) -> Bool {
        return lhs.restaurant == rhs.restaurant
    }
    
    var hashValue: Int { get { return restaurant.hashValue } }
    
    var distance: Double
    var restaurant: Restaurant
    
    init(_ distance: Double, _ restaurant: Restaurant) {
        self.distance = distance
        self.restaurant = restaurant
    }
}

class RestaurantCollection {
    var restaurants = Set<Restaurant>()
    
    func extend(with moreRestaurants: [Restaurant]) {
        for restaurant in moreRestaurants {
            restaurants.insert(restaurant)
        }
    }
}

class RestaurantGuide {
    private let maximalDistance: Double = 1000
    
    var currentRestaurants = Set<RestaurantWithDistance>()
    
    func update(_ collection: RestaurantCollection, _ userLocation: CLLocation) -> (Set<Restaurant>, Set<Restaurant>) {
        let currentRests = Set<Restaurant>(self.currentRestaurants.map() { $0.restaurant })
        
        let all = collection.restaurants.union(currentRests)
        let allWithinReach = all.filter() { $0.location.distance(from: userLocation) < maximalDistance }
        let allOutOfReach = all.subtracting(allWithinReach)
        let allCurrentOutOfReach = currentRests.intersection(allOutOfReach)
        let allNotCurrent = all.subtracting(currentRests)
        let allNotCurrentWithinReach = allNotCurrent.intersection(allWithinReach)
        
        currentRestaurants = Set<RestaurantWithDistance>(allWithinReach.map() { RestaurantWithDistance($0.location.distance(from: userLocation), $0) })
        
        return (allCurrentOutOfReach, allNotCurrentWithinReach)
    }
}

extension Array {
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Element:Key] {
        var dict = [Element:Key]()
        for element in self {
            dict[element] = selectKey(element)
        }
        return dict
    }
}
