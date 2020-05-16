//
//  Activity.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 16..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import Foundation

struct Activity : Decodable {
    let name: String
    let distance: Float
    let max_speed: Float
    let max_heartrate: Float?
    
    init(name: String, distance: Float, max_speed: Float, max_heartrate: Float) {
        self.name = name
        self.distance = distance
        self.max_speed = max_speed
        self.max_heartrate = max_heartrate
    }
}
