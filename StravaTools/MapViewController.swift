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

    private lazy var cachedActivities = { () -> [Activity] in
        var cached: [Activity] = []
        guard FileManager.default.fileExists(atPath: LoginViewController.allActivitiesCacheFullPath.path) else {
            print("Activities not cached yet")
            return cached
        }
        do {
            let data = try Data(contentsOf: LoginViewController.allActivitiesCacheFullPath, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            cached = try decoder.decode([Activity].self, from: data)
        } catch {
            return cached
        }
        return cached
    }()
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //get activities for currently visible map region
        let visibleActivities = cachedActivities.filter { (activity) -> Bool in
            var startVisible = false
            if let start_latlng = activity.start_latlng {
                let startLoc = CLLocationCoordinate2D(latitude: CLLocationDegrees(start_latlng[0]), longitude: CLLocationDegrees(start_latlng[1]))
                startVisible = MapViewController.coordinateInRegion(startLoc, mapView.region)
            }
            
            var endVisible = false
            if let end_latlng = activity.end_latlng {
                let endLoc = CLLocationCoordinate2D(latitude: CLLocationDegrees(end_latlng[0]), longitude: CLLocationDegrees(end_latlng[1]))
                endVisible = MapViewController.coordinateInRegion(endLoc, mapView.region)
            }
            
            return startVisible || endVisible
        }
        
        print("visibleActivities: \(visibleActivities.count)")
        
        guard let firstActivity = visibleActivities.first else {
            return
        }
        
        StravaAPIClient.sharedInstance.getLocationsForActivityWithID(id: firstActivity.id) { (locations, error) in
            self.showRouteOnMap(locations)
        }
    }
    
    func showRouteOnMap(_ coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count >= 2,
            let first = coordinates.first,
            let last = coordinates.last
        else {
            return
        }
        
        let sourcePlacemark = MKPlacemark(coordinate: first, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: last, addressDictionary: nil)

        let sourceAnnotation = MKPointAnnotation()

        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationAnnotation = MKPointAnnotation()

        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

//        mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
//        mapView.addOverlay(polyline, level: MKOverlayLevel.aboveRoads)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }
}
