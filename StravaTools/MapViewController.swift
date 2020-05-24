//
//  MapViewController.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 24..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    private var mapView = MKMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

}
