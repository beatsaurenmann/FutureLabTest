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
    
    @IBOutlet weak var adressField: UITextView!
    @IBOutlet weak var addressButton: UIButton!
    var addressFinder = AddressFinder()
    
    @IBOutlet weak var restaurantField: UITextView!
    @IBOutlet weak var restaurantButton: UIButton!
    var restaurantFinder = RestaurantFinder()
    
    var lastPosition: Position?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    @IBAction func updatePositionClicked(_ sender: Any) {
        positionLabel.text = "updating..."
        positionLabel.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            self.positioner.updatePosition({ p in self.displayPosition(p) }, self.displayPositionError)
        }
    }
    
    func displayPosition(_ position: Position) {
        DispatchQueue.main.async {
            self.positionLabel.text = position.DisplayString
            self.positionLabel.textColor = UIColor.black
        
            self.lastPosition = position
        }
    }
    
    func displayPositionError() {
        DispatchQueue.main.async {
            self.positionLabel.text = "something went wrong"
            self.positionLabel.textColor = UIColor.red
        }
    }
    
    @IBAction func updateAddressClicked(_ sender: Any) {
        adressField.text = "updating..."
        adressField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            self.addressFinder.updatePosition(self.lastPosition!,
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
    
    @IBAction func updateRestaurantClicked(_ sender: Any) {
        restaurantField.text = "updating..."
        restaurantField.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            self.restaurantFinder.updatePosition(self.lastPosition!,
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
