//
//  Route.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 04.04.21.
//  Copyright © 2021 Csaba Szigeti. All rights reserved.
//

import Foundation

struct Route : Codable {
    let distance: Float
    let elevation_gain: Float
    let estimated_moving_time: Int
    let id: Int
    let name: String
    
    init(distance: Float, elevation_gain: Float, estimated_moving_time: Int, id: Int, name: String) {
        self.distance = distance
        self.elevation_gain = elevation_gain
        self.estimated_moving_time = estimated_moving_time
        self.id = id
        self.name = name
    }
}
