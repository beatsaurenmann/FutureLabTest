//
//  RestaurantFinder.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation

class RestaurantFinder {
    
    var lastPosition: RestaurantInfo?
    
    init() {
        
    }
    
    func updatePosition(_ success: (RestaurantInfo) -> (), _ fail: () -> ()) {
        lastPosition = getCurrentPosition()
        
        sleep(3)
        
        if let position = lastPosition {
            success(position)
        } else {
            fail()
        }
    }
    
    
    func getCurrentPosition() -> RestaurantInfo? {
        return RestaurantInfo()
    }
    
}
