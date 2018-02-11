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

protocol IAppFlow {
    var userLocation: CLLocation? { get }
    var userHeading: CLHeading? { get }
    
    func onStartStopPressed()
}

class AppFlow : IAppFlow {
    
    private let viewController: ViewController
    private let tableController: RestaurantTableViewController
    
    private var navigationFlow: NavigationFlow!
    private var addressFlow: AddressFlow!
    private var restaurantsFlow: RestaurantsFlow!
    
    var userLocation: CLLocation?
    var userHeading: CLHeading?
    
    var collection = RestaurantCollection()
    
    init(_ viewController: ViewController, _ tableController: RestaurantTableViewController) {
        self.viewController = viewController
        self.tableController = tableController
        
        navigationFlow = NavigationFlow(
            viewController.setControlsToTrackingStarted,
            viewController.setControlsToTrackingEnded,
            onLocationChanged,
            onLocationChanged,
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
        viewController.updateLocationLabel()
        tableController.refreshCells()
        
        addressFlow.set(newLocation: newLocation)
        restaurantsFlow.set(newLocation: newLocation)
    }
    
    func onLocationChanged(_ newHeading: CLHeading) {
        userHeading = newHeading
        tableController.refreshCells()
    }
    
    var currentRestaurants = [Restaurant]()
    
    func onRestaurantsFound(_ newRestaurants: [Restaurant]) {
        collection.extend(with: newRestaurants)
        
        tableController.clearRows()
        
        let restaurants = collection.within(1000, of: userLocation!)
        tableController.display(restaurants)
        
        viewController.setControlsToRestaurantRequestEnded()
    }
}

class RestaurantCollection {
    var restaurants = Set<Restaurant>()
    
    func extend(with moreRestaurants: [Restaurant]) {
        for restaurant in moreRestaurants {
            restaurants.insert(restaurant)
        }
    }
    
    func within(_ dist: Double, of userLocation: CLLocation) -> [Restaurant] {
        let arrayToDist = Array(restaurants).toDictionary() { $0.location.distance(from: userLocation) }
        let restaurantsWithinReach = restaurants.filter() { arrayToDist[$0]! < dist }
        return restaurantsWithinReach.sorted() { arrayToDist[$0]! < arrayToDist[$1]! }
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
