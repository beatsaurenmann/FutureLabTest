//
//  Positioner.swift
//  FutureLabTest
//
//  Created by Beat Saurenmann on 07.02.18.
//  Copyright © 2018 Beat Saurenmann. All rights reserved.
//

import Foundation

class Positioner {
    
    var lastPosition: Position?
    
    init() {
        
    }
    
    func updatePosition(_ success: (Position) -> (), _ fail: () -> ()) {
        lastPosition = getCurrentPosition()
        
        sleep(3)
        
        if let position = lastPosition {
            success(position)
        } else {
            fail()
        }
    }
    
    
    func getCurrentPosition() -> Position? {
        return Position()
    }
    
}
