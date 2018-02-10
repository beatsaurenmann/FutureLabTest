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
    
    private var navigationFlow: NavigationFlow!
    private var addressFlow: AddressFlow!
    private var restaurantsFlow: RestaurantsFlow!
    
    var userLocation: CLLocation?
    var userHeading: CLHeading?
    
    init(_ viewController: ViewController) {
        self.viewController = viewController
        
        navigationFlow = NavigationFlow(
            viewController.setControlsToTrackingStarted,
            viewController.setControlsToTrackingEnded,
            onLocationChanged,
            onHeadingChanged,
            viewController.showNavigationError)
        addressFlow = AddressFlow(
            viewController.setControlsToAddressRequestStarted,
            viewController.showAddress,
            viewController.showAddressError)
        restaurantsFlow = RestaurantsFlow(
            viewController.setControlsToRestaurantRequestStarted,
            onNewRestaurantsWithinReachDetected,
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
        viewController.updateRestaurantDistances()
        viewController.removeDistantRestaurants()
    }
    
    func onHeadingChanged(_ newHeading: CLHeading) {
        userHeading = newHeading
        
        viewController.udpateCompasses(newHeading)
    }
    
    
    
    var guide = RestaurantGuide()
    
    func displayRestaurants(_ restaurants: [Restaurant], _ currentLocation: CLLocation) {
        for restaurant in restaurants {
            guide.restaurants.insert(restaurant)
        }
        updateRestaurantList(currentLocation)
    }
    
    func updateRestaurantList(_ currentLocation: CLLocation) {
        guide.userLocation = currentLocation
        DispatchQueue.main.async {
            self.viewController.tableView.reloadData()
        }
    }
    
    func onNewRestaurantsWithinReachDetected(_ restaurants: [Restaurant]) -> () {
        for restaurant in restaurants {
            guide.restaurants.insert(restaurant)
        }
        updateRestaurantList(userLocation!)
        
        viewController.addNewRestaurants()
        viewController.sortRestaurants()
    }
}
