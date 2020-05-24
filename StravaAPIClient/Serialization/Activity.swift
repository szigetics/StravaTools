//
//  Activity.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 16..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import Foundation

struct Activity : Codable {
    let name: String
    let distance: Float
    let max_speed: Float
    let max_heartrate: Float?
    let id: Int
    let start_latlng: [Float]?
    let end_latlng: [Float]?
    
    init(name: String, distance: Float, max_speed: Float, max_heartrate: Float, id: Int, start_latlng: [Float], end_latlng: [Float]) {
        self.name = name
        self.distance = distance
        self.max_speed = max_speed
        self.max_heartrate = max_heartrate
        self.id = id
        self.start_latlng = start_latlng
        self.end_latlng = end_latlng
    }
}
