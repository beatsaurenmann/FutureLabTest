//
//  ViewController.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var positionButton: UIButton!
    var positioner = Positioner()
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressButton: UIButton!
    var addressFinder = AddressFinder()
    
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var restaurantButton: UIButton!
    var restaurantFinder = RestaurantFinder()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func updatePositionClicked(_ sender: Any) {
        positionLabel.text = "updating..."
        positionLabel.textColor = UIColor.gray
        
        DispatchQueue.main.async {
            self.positioner.updatePosition({ p in self.displayPosition(p) }, self.displayPositionError)
        }
    }
    
    func displayPosition(_ position: Position) {
        positionLabel.text = position.DisplayString
        positionLabel.textColor = UIColor.black
    }
    
    func displayPositionError() {
        positionLabel.text = "something went wrong"
        positionLabel.textColor = UIColor.red
    }
    
    @IBAction func updateAddressClicked(_ sender: Any) {
        addressLabel.text = "updating..."
        addressLabel.textColor = UIColor.gray
        
        DispatchQueue.main.async {
            self.addressFinder.updatePosition({ p in self.displayAddress(p) }, self.displayAddressError)
        }
    }
    
    func displayAddress(_ address: Address) {
        addressLabel.text = address.DisplayString
        addressLabel.textColor = UIColor.black
    }
    
    func displayAddressError() {
        addressLabel.text = "something went wrong"
        addressLabel.textColor = UIColor.red
    }
    
    @IBAction func updateRestaurantClicked(_ sender: Any) {
        restaurantLabel.text = "updating..."
        restaurantLabel.textColor = UIColor.gray
        
        DispatchQueue.main.async {
            self.restaurantFinder.updatePosition({ p in self.displayRestaurant(p) }, self.displayRestaurantError)
        }
    }
    
    func displayRestaurant(_ restaurantInfo: RestaurantInfo) {
        restaurantLabel.text = restaurantInfo.DisplayString
        restaurantLabel.textColor = UIColor.black
    }
    
    func displayRestaurantError() {
        restaurantLabel.text = "something went wrong"
        restaurantLabel.textColor = UIColor.red
    }
    
}


class Position {
    
    init() {
    }
    
    var DisplayString: String { get { return "lat = 45.30149, long = 12.0430" } }
}


class Address {
    
    init() {
    }
    
    var DisplayString: String { get { return "Talwiesenstrasse 36, 8404 Winterthur" } }
}


class RestaurantInfo {
    
    init() {
    }
    
    var DisplayString: String { get { return "Oberibar" } }
}
