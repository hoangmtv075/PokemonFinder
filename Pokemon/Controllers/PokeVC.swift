//
//  PokeVC.swift
//  Pokemon
//
//  Created by Jack Ily on 05/10/2017.
//  Copyright © 2017 Jack Ily. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import GeoFire

class PokeVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    
    var ref: DatabaseReference!
    var geoFire: GeoFire!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.userTrackingMode = .follow
        
        mapView.delegate = self
        
        ref = Database.database().reference()
        geoFire = GeoFire(firebaseRef: ref)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authStatus()
    }
    
    func authStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func region(location: CLLocation) {
        let distance: CLLocationDistance = 2000
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance)
        
        mapView.setRegion(region, animated: true)
    }
    
    func createSighting(forLocation location: CLLocation, ofKey keyId: Int) {
        geoFire.setLocation(location, forKey: "\(keyId)")
    }
    
    func showSightingOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        var _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let annotation = PokeAnnotation(coordinate: location.coordinate, pokeNumber: Int(key)!)
                self.mapView.addAnnotation(annotation)
            }
        })
    }
    
    @IBAction func RandomPoke() {
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let keyId = arc4random_uniform(151) + 1
        
        createSighting(forLocation: location, ofKey: Int(keyId))
    }
}

//MARK: - mapView delegate

extension PokeVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let location = userLocation.location {
            if !mapHasCenteredOnce {
                mapHasCenteredOnce = true
                region(location: location)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView?
        let identifier = "Pokemon Sighting"
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
            
        } else if let dequeue = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            annotationView = dequeue
            annotationView?.annotation = annotation
            
        } else {
            let annotationViews = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            let button = UIButton(type: .detailDisclosure)
            
            annotationViews.rightCalloutAccessoryView = button
            annotationView = annotationViews
        }
        
        if let annotationView = annotationView, let annotation = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(annotation.pokeNumber)")
            
            let button = UIButton()
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.setImage(UIImage(named: "location-map-flat"), for: .normal)
            annotationView.rightCalloutAccessoryView = button
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingOnMap(location: location)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? PokeAnnotation {
            var placemark: MKPlacemark
            
            if #available(iOS 10.0, *) {
                placemark = MKPlacemark(coordinate: annotation.coordinate)
                
            } else {
                placemark = MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil)
            }
            
            let mapItem = MKMapItem(placemark: placemark)
            let distance: CLLocationDistance = 1000
            let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, distance, distance)
            let options: [String : Any] = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            
            MKMapItem.openMaps(with: [mapItem], launchOptions: options)
        }
    }
}

//MARK: locationManager delegate

extension PokeVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
}
