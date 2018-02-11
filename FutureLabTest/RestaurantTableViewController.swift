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
    
    var appFlow: IAppFlow!
    
    var restaurants = [Restaurant]()
    
    func clearRows() {
        DispatchQueue.main.async {
            let previousRestaurantsCount = self.restaurants.count
            
            self.tableView.beginUpdates()
            if previousRestaurantsCount > 0 {
                for i in 0...previousRestaurantsCount-1 {
                    self.tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                }
            }
            self.tableView.endUpdates()
        }
    }
    
    func display(_ restaurants: [Restaurant]) {
        DispatchQueue.main.async {
            self.restaurants = restaurants
            
            self.tableView.beginUpdates()
            if self.restaurants.count > 0 {
                for i in 0...self.restaurants.count-1 {
                    self.tableView.insertRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                }
            }
            self.tableView.endUpdates()
        }
    }
    
    func refreshCells() {
        DispatchQueue.main.async {
            for cell in self.tableView.visibleCells {
                cell.setNeedsDisplay()
            }
            self.sortCells()
        }
    }
    
    func sortCells() {
        DispatchQueue.main.async {
            let restaurantsBefore = Array(self.restaurants)
            let arrayToDist = restaurantsBefore.toDictionary() { $0.location.distance(from: self.appFlow.userLocation!) }
            self.restaurants = restaurantsBefore.sorted() { arrayToDist[$0]! < arrayToDist[$1]! }
            self.sort(restaurantsBefore, self.restaurants)
        }
    }
    
    private func sort(_ objectsBeforeSort: [Restaurant], _ objectsNow: [Restaurant]) {
        self.tableView.beginUpdates()
        for i in 0..<objectsNow.count {
            let newRow: Int = objectsNow.index(of: objectsBeforeSort[i])!
            self.tableView.moveRow(at: IndexPath(row: i, section: 0), to: IndexPath(row: newRow, section: 0))
        }
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! RestaurantTableViewCell
        cell.appFlow = appFlow
        cell.restaurant = restaurants[indexPath.row]
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
    
    var appFlow: IAppFlow!
    var restaurant: Restaurant! { didSet { nameLabel.text = restaurant.restaurantName } }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distLabel: UILabel!
    @IBOutlet weak var arrowView: ArrowView!
    @IBOutlet weak var attributesTable: UITableView!
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        
        updateDistanceLabel()
        rotate()
    }
    
    func updateDistanceLabel() {
        distLabel.text = "\(Int(getDistanceToUser()))m"
    }
    
    func getDistanceToUser() -> Double {
        guard let loc = appFlow.userLocation else {
            return 0
        }
        return restaurant.location.distance(from: loc)
    }
    
    func rotate() {
        guard let loc = appFlow.userLocation, let heading = appFlow.userHeading else {
            return
        }
        
        let northAngleR = CGFloat(-heading.magneticHeading * .pi/180)
        
        let angleFromNorthToTargetR = loc.bearingToLocationRadian(restaurant.location)
        
        DispatchQueue.main.async {
            self.arrowView.transform = CGAffineTransform(rotationAngle: northAngleR + angleFromNorthToTargetR)
        }
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
