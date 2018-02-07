//
//  ViewController.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import UIKit
import CoreLocation
import Nominatim

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopTracking()
    }
    
    //MARK: GPS tracker
    
    @IBOutlet weak var startStopButton: UIButton!
    
    var positioner = Positioner()
    @IBOutlet weak var locationLabel: UILabel!
    
    var currentLocation: CLLocation?
    var latestSearchLocation: CLLocation?
    var latestSearch = Date()
    
    @IBAction func updateLocationClicked(_ sender: Any) {
        if positioner.isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }
    
    func startTracking() {
        startStopButton.setTitle("Stop Tracking",for: .normal)
        
        locationLabel.text = "waiting for GPS signal..."
        locationLabel.textColor = UIColor.gray
        
        self.positioner.startTracking({ p in self.displayLocation(p) }, self.displayErrorFromPositioner)
    }
    
    func stopTracking() {
        startStopButton.setTitle("Start Tracking",for: .normal)
        
        self.positioner.stopTracking()
        
        locationLabel.text = "n.a."
        locationLabel.textColor = UIColor.gray
        
        currentLocation = nil
    }
    
    func displayLocation(_ location: CLLocation) {
        DispatchQueue.main.async {
            if (self.positioner.isTracking) {
                self.locationLabel.text = location.DisplayString
                self.locationLabel.textColor = UIColor.black
                
                self.currentLocation = location
                self.triggerSearchUponLocationChange()
            }
        }
    }
    
    func displayErrorFromPositioner(_ message: String) {
        DispatchQueue.main.async {
            self.locationLabel.text = "Error: \(message)"
            self.locationLabel.textColor = UIColor.red
        }
    }
    
    func triggerSearchUponLocationChange() {
        if !positioner.isTracking {
            return
        }
        
        var searchIsOutdated = false
        
        if let currentLocation = currentLocation {
            if let latestSearchLocation = latestSearchLocation {
                let coveredDistance: CLLocationDistance = latestSearchLocation.distance(from: currentLocation)
                if coveredDistance.magnitude > 5 && latestSearch.addingTimeInterval(10) < Date() {
                    searchIsOutdated = true
                }
            } else {
                searchIsOutdated = true
            }
        }
        
        if searchIsOutdated {
            latestSearchLocation = currentLocation
            latestSearch = Date()
            updateAddress()
            updateRestaurantGuide()
        }
    }
    
    //MARK: Closest address
    
    @IBOutlet weak var adressField: UITextView!
    
    func updateAddress() {
        guard let loc = currentLocation else {
            return
        }
        
        adressField.text = "updating..."
        adressField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            AddressFinder.findAddress(loc, { p in self.displayAddress(p) }, self.displayAddressError)
        }
    }
    
    func displayAddress(_ address: Location) {
        DispatchQueue.main.async {
            self.adressField.text = address.DisplayString
            self.adressField.textColor = UIColor.black
        }
    }
    
    func displayAddressError(_ description: String) {
        DispatchQueue.main.async {
            self.adressField.text = "Error: \(description)"
            self.adressField.textColor = UIColor.red
        }
    }
    
    //MARK: Restaurants in the neighbourhood
    
    @IBOutlet weak var restaurantField: UITextView!
    
    var currentGuide: RestaurantGuide?
    
    func updateRestaurantGuide() {
        guard let loc = currentLocation else {
            return
        }
        
        restaurantField.text = "updating..."
        restaurantField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            RestaurantFinder.updatePosition(loc, { p in self.displayRestaurants(p, loc) }, self.displayRestaurantError )
        }
    }
    
    func displayRestaurants(_ restaurantGuide: RestaurantGuide, _ currentLocation: CLLocation) {
        currentGuide = restaurantGuide
        updateRestaurantList(currentLocation)
    }
    
    func updateRestaurantList(_ currentLocation: CLLocation) {
        DispatchQueue.main.async {
            self.restaurantField.text = self.currentGuide!.getListOfRestaurants(for: currentLocation)
            self.restaurantField.textColor = UIColor.black
        }
    }
    
    func displayRestaurantError(_ errorMessage: String) {
        DispatchQueue.main.async {
            self.restaurantField.text = "something went wrong"
            self.restaurantField.textColor = UIColor.red
        }
    }
}
