//
//  MapViewController.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 24..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    private var mapView = MKMapView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        mapView.delegate = self
    }
    
    private static func coordinateInRegion(_ coord: CLLocationCoordinate2D, _ region: MKCoordinateRegion) -> Bool {
        let center = region.center
        let span = region.span

        var result = true
        result = result && cos((center.latitude - coord.latitude) * Double.pi / 180.0) > cos(span.latitudeDelta / 2.0 * Double.pi / 180.0)
        result = result && cos((center.longitude - coord.longitude) * Double.pi / 180.0) > cos(span.longitudeDelta / 2.0 * Double.pi / 180.0)
        return result
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //get activities for currently visible map region
//        MapViewController.coordinateInRegion(<#T##coord: CLLocationCoordinate2D##CLLocationCoordinate2D#>, mapView.region)
    }
}
