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
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        stopTracking()
    }
    
    //MARK: GPS tracker
    
    @IBOutlet weak var startStopButton: UIButton!
    
    var positioner = Positioner()
    @IBOutlet weak var locationLabel: UILabel!
    
    var currentLocation: CLLocation?
    var currentHeading: CLHeading?
    var latestSearchLocation: CLLocation?
    var latestSearch = Date()
    
    @IBOutlet weak var compassArrowView: ArrowView!
    
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
        
        self.positioner.startTracking({ p in self.displayLocation(p) }, { h in self.headingChanged(h) }, self.displayErrorFromPositioner)
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
    
    func headingChanged(_ heading: CLHeading) {
        currentHeading = heading
        
        DispatchQueue.main.async {
            let transform = CGAffineTransform(rotationAngle: CGFloat(-heading.magneticHeading * .pi/180))
            self.compassArrowView.transform = transform
            
            for view in self.updatableViews {
                view.setNeedsDisplay()
            }
        }
    }
    
    var updatableViews = [UIView]()
    
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
    
    @IBOutlet weak var adressLabel: UILabel!
    
    func updateAddress() {
        guard let loc = currentLocation else {
            return
        }
        
        adressLabel.text = "updating..."
        adressLabel.textColor = UIColor.gray
        
        DispatchQueue.global(qos: .default).async {
            AddressFinder.findAddress(loc, { p in self.displayAddress(p) }, self.displayAddressError)
        }
    }
    
    func displayAddress(_ address: Location) {
        DispatchQueue.main.async {
            self.adressLabel.text = address.DisplayString
            self.adressLabel.textColor = UIColor.black
        }
    }
    
    func displayAddressError(_ description: String) {
        DispatchQueue.main.async {
            self.adressLabel.text = "Error: \(description)"
            self.adressLabel.textColor = UIColor.red
        }
    }
    
    //MARK: Restaurants in the neighbourhood
    
    var currentGuide: RestaurantGuide?
    
    func updateRestaurantGuide() {
        guard let loc = currentLocation else {
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            RestaurantFinder.updatePosition(loc, { p in self.displayRestaurants(p, loc) }, self.displayRestaurantError )
        }
    }
    
    func displayRestaurants(_ restaurantGuide: RestaurantGuide, _ currentLocation: CLLocation) {
        currentGuide = restaurantGuide
        updateRestaurantList(currentLocation)
    }
    
    func updateRestaurantList(_ currentLocation: CLLocation) {
        updatableViews.removeAll()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func displayRestaurantError(_ errorMessage: String) {
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let currentLocation = currentLocation, let currentGuide = currentGuide else {
            return 0
        }
        
        return currentGuide.getRestaurants(for: currentLocation).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! RestaurantTableViewCell
        let rest = currentGuide!.getRestaurants(for: currentLocation!)[indexPath.row]
        cell.nameLabel?.text = rest.1
        cell.addressLabel?.text = rest.2
        cell.distLabel?.text = "\(rest.0)m"
        cell.location = rest.3
        cell.currentLocation = currentLocation
        cell.currentHeading = { () in return self.currentHeading }
        updatableViews.append(cell)
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
    @IBOutlet weak var arrowView: ArrowView!
    
    var currentLocation: CLLocation?
    var currentHeading: () -> CLHeading? = { () in return nil }
    var location: CLLocation?
    
    func rotate(_ loc: CLLocation, _ heading: CLHeading, _ target: CLLocation) {
        let northAngleR = CGFloat(-heading.magneticHeading * .pi/180)
        
        let angleFromNorthToTargetR = loc.bearingToLocationRadian(target)
        
        DispatchQueue.main.async {
            self.arrowView.transform = CGAffineTransform(rotationAngle: northAngleR + angleFromNorthToTargetR)
        }
    }
}

public extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
        
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }
    
    func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

private extension Double {
    var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
    var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
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
