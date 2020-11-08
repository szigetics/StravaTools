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
    let type: String
    let start_date_local: String
    
    init(name: String, distance: Float, max_speed: Float, max_heartrate: Float, id: Int, start_latlng: [Float], end_latlng: [Float], type: String, start_date_local: String) {
        self.name = name
        self.distance = distance
        self.max_speed = max_speed
        self.max_heartrate = max_heartrate
        self.id = id
        self.start_latlng = start_latlng
        self.end_latlng = end_latlng
        self.type = type
        self.start_date_local = start_date_local
    }
    
    func start_date_local_date() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from:start_date_local)!
        return date
    }
}
