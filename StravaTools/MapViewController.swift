//
//  MapViewController.swift
//  StravaTools
//
//  Created by Csaba Szigeti on 2020. 05. 24..
//  Copyright © 2020. Csaba Szigeti. All rights reserved.
//

import UIKit
import MapKit

class ActivityAnnotation: NSObject, Decodable, MKAnnotation {
    
    enum ActivityAnnotationType: Int, Decodable {
        case run
        case bicycle
//        case other
    }
    
    var type: ActivityAnnotationType = .bicycle
    let activity: Activity
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    
    init(_ activity: Activity) {
        self.activity = activity
    }
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            // For most uses, `coordinate` can be a standard property declaration without the customized getter and setter shown here.
            // The custom getter and setter are needed in this case because of how it loads data from the `Decodable` protocol.
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}

private let bikeClusterID = "activityClusterID"

/// - Tag: BicycleAnnotationView
class BicycleAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "bicycleAnnotation"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = bikeClusterID
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Tag: DisplayConfiguration
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.bicycleColor
        glyphImage = #imageLiteral(resourceName: "bicycle")
    }
}

private let runClusterID = "activityClusterID"

/// - Tag: RunAnnotationView
class RunAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "runAnnotation"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = runClusterID
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Tag: DisplayConfiguration
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.bicycleColor
        glyphImage = #imageLiteral(resourceName: "run")
    }
}

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
        
        mapView.delegate = self
        
        registerAnnotationViewClasses()
        
        showStartPointsOnMap()
        
        let loadAllVisibleButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(loadAllVisibleButtonPressed(_:)))
        self.navigationItem.rightBarButtonItems = [loadAllVisibleButton]
    }
    
    @objc func loadAllVisibleButtonPressed(_ sender: Any) {
        let visibleActivities = cachedActivities.filter { (activity) -> Bool in
            var startVisible = false
            if let start_latlng = activity.start_latlng {
                let startLoc = CLLocationCoordinate2D(latitude: CLLocationDegrees(start_latlng[0]), longitude: CLLocationDegrees(start_latlng[1]))
                startVisible = MapViewController.coordinateInRegion(startLoc, mapView.region)
            }
            
            return startVisible
        }
        
        for visibleActivity in visibleActivities {
            StravaAPIClient.sharedInstance.getLocationsForActivityWithID(id: visibleActivity.id) { (locations, error) in
                self.showRouteOnMap(locations)
            }
        }
    }
    
    private func registerAnnotationViewClasses() {
        mapView.register(BicycleAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(RunAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }
    
    private func showStartPointsOnMap() {
        let addAnnotationForActivity = { (activity: Activity, type: ActivityAnnotation.ActivityAnnotationType) in
            guard let start_latlng = activity.start_latlng else {
                return
            }
            let startLoc = CLLocationCoordinate2D(latitude: CLLocationDegrees(start_latlng[0]), longitude: CLLocationDegrees(start_latlng[1]))
            
            let startAnnotation = ActivityAnnotation(activity)
            startAnnotation.coordinate = startLoc
            startAnnotation.type = type
            self.mapView.addAnnotation(startAnnotation)
        }
        
        let addAnnotationsForActivityType = { (type: ActivityAnnotation.ActivityAnnotationType) in
            let stringForActivityType: String = {
                switch type {
                case .bicycle:
                    return "Ride"
                case .run:
                    return "Run"
                }
            }()
            
            let activitiesWithType = self.cachedActivities.filter { (activity) -> Bool in
                return activity.type == stringForActivityType
            }
            activitiesWithType.forEach { (activity) in
                addAnnotationForActivity(activity, type)
            }
        }
        
        addAnnotationsForActivityType(.bicycle)
        addAnnotationsForActivityType(.run)
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
}

extension UIControl {
    
    /// Typealias for UIControl closure.
    public typealias UIControlTargetClosure = (UIControl) -> ()
    
    private class UIControlClosureWrapper: NSObject {
        let closure: UIControlTargetClosure
        init(_ closure: @escaping UIControlTargetClosure) {
            self.closure = closure
        }
    }
    
    private struct AssociatedKeys {
        static var targetClosure = "targetClosure"
    }
    
    private var targetClosure: UIControlTargetClosure? {
        get {
            guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.targetClosure) as? UIControlClosureWrapper else { return nil }
            return closureWrapper.closure
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.targetClosure, UIControlClosureWrapper(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc func closureAction() {
        guard let targetClosure = targetClosure else { return }
        targetClosure(self)
    }
    
    public func addAction(for event: UIControl.Event, closure: @escaping UIControlTargetClosure) {
        targetClosure = closure
        addTarget(self, action: #selector(UIControl.closureAction), for: event)
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    func showRouteOnMap(_ coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count >= 2,
            let first = coordinates.first,
            let last = coordinates.last
            else {
                return
        }

//        let sourcePlacemark = MKPlacemark(coordinate: first, addressDictionary: nil)
//        let destinationPlacemark = MKPlacemark(coordinate: last, addressDictionary: nil)
//
//        let sourceAnnotation = MKPointAnnotation()
//
//        if let location = sourcePlacemark.location {
//            sourceAnnotation.coordinate = location.coordinate
//        }
//
//        let destinationAnnotation = MKPointAnnotation()
//
//        if let location = destinationPlacemark.location {
//            destinationAnnotation.coordinate = location.coordinate
//        }
//
//        mapView.addAnnotation(sourceAnnotation)
//        mapView.addAnnotation(destinationAnnotation)

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline, level: MKOverlayLevel.aboveRoads)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? ActivityAnnotation else { return nil }
        
        var result: MKMarkerAnnotationView? = nil
        
        switch annotation.type {
        case .bicycle:
            result = BicycleAnnotationView(annotation: annotation, reuseIdentifier: BicycleAnnotationView.ReuseID)
        case .run:
            result = RunAnnotationView(annotation: annotation, reuseIdentifier: RunAnnotationView.ReuseID)
        }
        
        let btnShow = UIButton(type: .contactAdd)
        let btnOpen = UIButton(type: .detailDisclosure)
        let stack = UIStackView(arrangedSubviews: [btnShow, btnOpen])
        btnShow.addAction(for: .touchUpInside) { _ in
            StravaAPIClient.sharedInstance.getLocationsForActivityWithID(id: annotation.activity.id) { (locations, error) in
                self.showRouteOnMap(locations)
            }
        }
        btnOpen.addAction(for: .touchUpInside) { _ in
            let openInBrowser = {
                guard let url = URL(string: "https://www.strava.com/activities/\(annotation.activity.id)") else { return }
                UIApplication.shared.open(url, completionHandler: nil)
            }
            
            guard let url = URL(string: "strava://activities/\(annotation.activity.id)") else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { (success) in
                    if !success {
                        openInBrowser()
                    }
                }
            } else {
                openInBrowser()
            }
        }
        result!.detailCalloutAccessoryView = stack
        result!.canShowCallout = true
        
        return result!
    }
}
