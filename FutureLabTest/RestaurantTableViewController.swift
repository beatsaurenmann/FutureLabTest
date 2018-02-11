//
//  RestaurantTableViewController.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 10.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import UIKit
import CoreLocation
import Nominatim

class RestaurantTableViewController: UITableViewController {
    
    var appFlow: AppFlow!
    
    var restaurants = [RestaurantWithDistance]()
    
    func insertRestaurantAtIndex() {
        
    }
    
    func removeRestaurantAtIndex() {
        
    }
    
    func sort(_ objectsBeforeSort: [Restaurant], _ objects: [Restaurant]) {
        tableView.beginUpdates()
        for i in 0..<objects.count {
            // newRow will get the new row of an object.  i is the old row.
            let newRow: Int = objects.index(of: objectsBeforeSort[i])!
            tableView.moveRow(at: IndexPath(row: i, section: 0), to: IndexPath(row: newRow, section: 0))
        }
        tableView.endUpdates()
    }
    
    func update(_ all: Set<RestaurantWithDistance>, _ new: Set<Restaurant>, _ obsolete: Set<Restaurant>) {
        restaurants = all.sorted() { (first, second) -> Bool in
            return first.distance < second.distance
        }
        
        tableView.beginUpdates()
        let previousRowCount = tableView.numberOfRows(inSection: 0)-1
        if previousRowCount > 0 {
            for i in 0...previousRowCount {
                tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)
            }
        }
        
        let newRowCount = restaurants.count-1
        if newRowCount > 0 {
            for i in 0...newRowCount {
                tableView.insertRows(at: [IndexPath(row: i, section: 0)], with: .fade)
            }
        }
        tableView.endUpdates()
    }
    
    func updateDistances(_ newLocation: CLLocation) {
        DispatchQueue.main.async {
            for cell in self.tableView.visibleCells {
                (cell as! RestaurantTableViewCell).currentLocation = newLocation
            }
        }
    }
    
    func udpateCompasses(_ newHeading: CLHeading) {
        DispatchQueue.main.async {
            for view in self.tableView.visibleCells {
                (view as! RestaurantTableViewCell).currentHeading = newHeading
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! RestaurantTableViewCell
        let restWithDist = restaurants[indexPath.row]
        cell.restaurant = restWithDist.restaurant
        cell.currentLocation = appFlow.userLocation
        cell.setNeedsDisplay()
        return cell
    }
    
    var thereIsCellTapped = false
    var selectedRowIndex = -1
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == selectedRowIndex && thereIsCellTapped {
            return 130
        }
        return 42
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedRowIndex != indexPath.row {
            self.thereIsCellTapped = true
            self.selectedRowIndex = indexPath.row
        }
        else {
            self.thereIsCellTapped = false
            self.selectedRowIndex = -1
        }
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
}

class RestaurantTableViewCell : UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        attributesTable.dataSource = self
        attributesTable.delegate = self
        
        rotate()
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distLabel: UILabel!
    @IBOutlet weak var attributesTable: UITableView!
    
    var restaurant: Restaurant! {
        didSet {
            nameLabel.text = restaurant.restaurantName
            
            DispatchQueue.main.async {
                self.attributesTable.reloadData()
            }
        }
    }
    
    var dist: Double {
        get {
            guard let loc = currentLocation else {
                return 0
            }
            return restaurant.location.distance(from: loc)
        }
    }
    
    @IBOutlet weak var arrowView: ArrowView!
    
    var currentLocation: CLLocation? { didSet { rotate(); updateDistanceLabel() } }
    var currentHeading: CLHeading? { didSet { rotate(); updateDistanceLabel() } }
    
    func rotate() {
        guard let loc = currentLocation, let heading = currentHeading else {
            return
        }
        
        let northAngleR = CGFloat(-heading.magneticHeading * .pi/180)
        
        let angleFromNorthToTargetR = loc.bearingToLocationRadian(restaurant.location)
        
        DispatchQueue.main.async {
            self.arrowView.transform = CGAffineTransform(rotationAngle: northAngleR + angleFromNorthToTargetR)
        }
    }
    
    func updateDistanceLabel() {
        distLabel.text = "\(Int(dist))m"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let restaurant = restaurant else {
            return 0
        }
        return min(4, restaurant.attributes.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeCell
        cell.label.text = "\(restaurant.attributes[indexPath.row].0) = \(restaurant.attributes[indexPath.row].1)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 21
    }
}

class AttributeCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
}

class ArrowView: UIView {
    override func draw(_ dirtyRect: CGRect) {
        UIColor.black.set()
        let path = UIBezierPath.arrow(from: CGPoint(x: 20, y: 35), to: CGPoint(x: 20, y: 5), tailWidth: 2, headWidth: 5, headLength: 8)
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
