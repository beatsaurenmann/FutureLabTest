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
    
    var appFlow: IAppFlow!
    
    var tableViewController = RestaurantTableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appFlow = AppFlow(self, tableViewController)
        
        navigationActivityIndicator.hidesWhenStopped = true
        addressActivityIndicator.hidesWhenStopped = true
        restaurantActivityIndicator.hidesWhenStopped = true
        
        tableViewController.appFlow = appFlow
        tableViewController.tableView = tableView
        tableView.delegate = tableViewController
        tableView.dataSource = tableViewController
    }
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var roadLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var navigationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var addressActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var restaurantActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func startStopTrackingClicked(_ sender: Any) {
        appFlow.onStartStopPressed()
    }
    
    func setControlsToTrackingStarted() {
        DispatchQueue.main.async {
            self.startStopButton.setTitle("Stop Tracking",for: .normal)
            self.navigationActivityIndicator.startAnimating()
        }
    }
    
    func setControlsToTrackingEnded() {
        DispatchQueue.main.async {
            self.startStopButton.setTitle("Start Tracking",for: .normal)
            self.navigationActivityIndicator.stopAnimating()
        }
    }
    
    func updateLocationLabel() {
        DispatchQueue.main.async {
            let newLocation = self.appFlow.userLocation!
            self.locationLabel.text = newLocation.DisplayString
            
            self.accuracyLabel.text = "±\(Int(newLocation.horizontalAccuracy))m"
            if newLocation.horizontalAccuracy <= 10 {
                self.navigationActivityIndicator.stopAnimating()
            } else if !self.navigationActivityIndicator.isAnimating {
                self.navigationActivityIndicator.startAnimating()
            }
        }
    }
    
    func showNavigationError(_ message: String) {
        DispatchQueue.main.async {
            self.locationLabel.text = "Error: \(message)"
        }
    }
    
    func setControlsToAddressRequestStarted() {
        DispatchQueue.main.async {
            self.addressActivityIndicator.startAnimating()
        }
    }
    
    func showAddress(_ address: Location) {
        DispatchQueue.main.async {
            self.addressActivityIndicator.stopAnimating()
            self.roadLabel.text = address.RoadDisplayString
            self.cityLabel.text = address.CityDisplayString
        }
    }
    
    func showAddressError(_ description: String) {
        DispatchQueue.main.async {
            self.roadLabel.text = "Error: \(description)"
            self.cityLabel.text = ""
        }
    }
    
    func setControlsToRestaurantRequestStarted() {
        DispatchQueue.main.async {
            self.restaurantActivityIndicator.startAnimating()
        }
    }
    
    func setControlsToRestaurantRequestEnded() {
        DispatchQueue.main.async {
            self.restaurantActivityIndicator.stopAnimating()
        }
    }
    
    func showRestaurantError(_ errorMessage: String) {
    }
}
