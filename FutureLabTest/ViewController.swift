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

class ViewController: UIViewController, UITableViewDataSource {
    
    var appFlow: AppFlow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appFlow = AppFlow(self)
    }
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var compassArrowView: ArrowView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func startStopTrackingClicked(_ sender: Any) {
        appFlow.onStartStopPressed()
    }
    
    func setControlsToTrackingStarted() {
        DispatchQueue.main.async {
            self.startStopButton.setTitle("Stop Tracking",for: .normal)
            
            self.locationLabel.text = "waiting for GPS signal..."
            self.locationLabel.textColor = UIColor.gray
        }
    }
    
    func setControlsToTrackingEnded() {
        DispatchQueue.main.async {
            self.startStopButton.setTitle("Start Tracking",for: .normal)
            
            self.locationLabel.textColor = UIColor.gray
        }
    }
    
    func updateLocationLabel(_ newLocation: CLLocation) {
        DispatchQueue.main.async {
            self.locationLabel.text = newLocation.DisplayString
            self.locationLabel.textColor = UIColor.black
        }
    }
    
    func udpateCompasses(_ newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.compassArrowView.transform = CGAffineTransform(rotationAngle: CGFloat(-newHeading.magneticHeading * .pi/180))
            
            for view in self.tableView.visibleCells {
                view.setNeedsDisplay()
            }
        }
    }
    
    func showNavigationError(_ message: String) {
        DispatchQueue.main.async {
            self.locationLabel.text = "Error: \(message)"
            self.locationLabel.textColor = UIColor.red
        }
    }
    
    func setControlsToAddressRequestStarted() {
        DispatchQueue.main.async {
            self.adressLabel.text = "updating..."
            self.adressLabel.textColor = UIColor.gray
        }
    }
    
    func showAddress(_ address: Location) {
        DispatchQueue.main.async {
            self.adressLabel.text = address.DisplayString
            self.adressLabel.textColor = UIColor.black
        }
    }
    
    func showAddressError(_ description: String) {
        DispatchQueue.main.async {
            self.adressLabel.text = "Error: \(description)"
            self.adressLabel.textColor = UIColor.red
        }
    }
    
    func setControlsToRestaurantRequestStarted() {
    }
    
    func updateRestaurantDistances() {
    }
    
    func removeDistantRestaurants() {
    }
    
    func addNewRestaurants() {
    }
    
    func sortRestaurants() {
    }
    
    func showRestaurantError(_ errorMessage: String) {
    }
    
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appFlow.guide.restaurantsWithinReach.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! RestaurantTableViewCell
        let (dist,rest) = appFlow.guide.restaurantsWithinReach[indexPath.row]
        cell.restaurant = rest
        cell.dist = dist
        cell.location = rest.location
        cell.currentLocation = appFlow.userLocation
        cell.currentHeading = { () in return self.appFlow.userHeading }
        cell.setNeedsDisplay()
        return cell
    }
}

class RestaurantTableViewCell : UITableViewCell {
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        
        guard let loc = currentLocation, let heading = currentHeading(), let target = location else {
            return
        }
        
        rotate(loc, heading, target)
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var distLabel: UILabel!
    
    var restaurant: Restaurant! {
        didSet {
            nameLabel?.text = restaurant.restaurantName
            addressLabel?.text = restaurant.Address
        }
    }
    
    var dist: Int = 0 {
        didSet {
            distLabel?.text = "\(dist)m"
        }
    }
    
    @IBOutlet weak var arrowView: ArrowView!
    
    var currentLocation: CLLocation?
    var currentHeading: () -> CLHeading? = { () in return CLHeading() }
    var location: CLLocation?
    
    func rotate(_ loc: CLLocation, _ heading: CLHeading, _ target: CLLocation) {
        let northAngleR = CGFloat(-heading.magneticHeading * .pi/180)
        
        let angleFromNorthToTargetR = loc.bearingToLocationRadian(target)
        
        DispatchQueue.main.async {
            self.arrowView.transform = CGAffineTransform(rotationAngle: northAngleR + angleFromNorthToTargetR)
        }
    }
}

class ArrowView: UIView {
    override func draw(_ dirtyRect: CGRect) {
        UIColor.black.set()
        let path = UIBezierPath.arrow(from: CGPoint(x: 22, y: 35), to: CGPoint(x: 22, y: 5), tailWidth: 2, headWidth: 5, headLength: 8)
        path.lineWidth = CGFloat(3)
        path.stroke()
    }
}

extension UIBezierPath {
    static func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { return CGPoint(x: x, y: y) }
        let points: [CGPoint] = [
            p(0, tailWidth / 2),
            p(tailLength, tailWidth / 2),
            p(tailLength, headWidth / 2),
            p(length, 0),
            p(tailLength, -headWidth / 2),
            p(tailLength, -tailWidth / 2),
            p(0, -tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform)
        path.closeSubpath()
        
        return self.init(cgPath: path)
    }
}
