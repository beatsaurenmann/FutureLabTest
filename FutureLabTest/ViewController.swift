//
//  ViewController.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    var latestSearchLocation: CLLocation?
    
    @IBOutlet weak var adressField: UITextView!
    @IBOutlet weak var addressButton: UIButton!
    var addressFinder = AddressFinder()
    
    @IBOutlet weak var restaurantField: UITextView!
    @IBOutlet weak var restaurantButton: UIButton!
    var restaurantFinder = RestaurantFinder()
    
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //MARK: GPS tracker
    
    @IBOutlet weak var startStopButton: UIButton!
    
    var positioner = Positioner()
    @IBOutlet weak var locationLabel: UILabel!
    
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
    }
    
    func displayLocation(_ location: CLLocation) {
        DispatchQueue.main.async {
            if (self.positioner.isTracking) {
                self.locationLabel.text = location.DisplayString
                self.locationLabel.textColor = UIColor.black
                
                self.currentLocation = location
            }
        }
    }
    
    func displayErrorFromPositioner(_ message: String) {
        DispatchQueue.main.async {
            self.locationLabel.text = "Error: \(message)"
            self.locationLabel.textColor = UIColor.red
        }
    }
    
    //MARK: Closest address
    
    @IBAction func updateAddressClicked(_ sender: Any) {
        let distanceBetween: CLLocationDistance = latestSearchLocation!.distance(from: currentLocation!)
        //        distance.text = String(format: "%.2f", distanceBetween)
        
        
        adressField.text = "updating..."
        adressField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            self.addressFinder.updatePosition(self.currentLocation!,
                { p in
                    self.displayAddress(p)
                },
                self.displayAddressError
            )
        }
    }
    
    func displayAddress(_ address: Address) {
        DispatchQueue.main.async {
            self.adressField.text = address.DisplayString
            self.adressField.textColor = UIColor.black
        }
    }
    
    func displayAddressError() {
        DispatchQueue.main.async {
            self.adressField.text = "something went wrong"
            self.adressField.textColor = UIColor.red
        }
    }
    
    //MARK: Restaurants in the neighbourhood
    
    @IBAction func updateRestaurantClicked(_ sender: Any) {
        restaurantField.text = "updating..."
        restaurantField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            self.restaurantFinder.updatePosition(self.currentLocation!,
                { p in
                    self.displayRestaurant(p)
                },
                self.displayRestaurantError
            )
        }
    }
    
    func displayRestaurant(_ restaurantInfo: RestaurantsInfo) {
        DispatchQueue.main.async {
            self.restaurantField.text = restaurantInfo.DisplayString
            self.restaurantField.textColor = UIColor.black
        }
    }
    
    func displayRestaurantError() {
        DispatchQueue.main.async {
            self.restaurantField.text = "something went wrong"
            self.restaurantField.textColor = UIColor.red
        }
    }
}
