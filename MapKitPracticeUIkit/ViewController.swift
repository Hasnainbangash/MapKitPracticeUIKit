//
//  ViewController.swift
//  MapKitPracticeUIkit
//
//  Created by Elexoft on 01/01/2025.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    let destination = CLLocationCoordinate2D(latitude: 40.850678, longitude: -73.945212)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        searchBar.delegate = self
        mapView.delegate = self
        
        setupProfileImage()
        setupLocationManager()
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            setInitialMapLocations()
        }
        
    }
    
    func setupProfileImage() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setInitialMapLocations() {
        
        let initialLocation = CLLocationCoordinate2D(latitude: 49.254606, longitude: -123.217643)
        
        let region = MKCoordinateRegion(
            center: initialLocation,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func locationButtonPressed(_ sender: UIButton) {
        
        print("Button pressed")
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        
    }
    
}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            //for getting just one route
            if let route = unwrappedResponse.routes.first {
                self.mapView.removeOverlays(self.mapView.overlays)
                //show on map
                self.mapView.addOverlay(route.polyline)
                //set the map area to show the route
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
                
                // Add annotations for source and destination
                self.mapView.removeAnnotations(self.mapView.annotations)
                
                let sourcePin = MKPointAnnotation()
                sourcePin.coordinate = pickupCoordinate
                sourcePin.title = "Current Location"
                
                let destinationPin = MKPointAnnotation()
                destinationPin.coordinate = destinationCoordinate
                destinationPin.title = "Destination"
                
                self.mapView.addAnnotations([sourcePin, destinationPin])
            }
            
            //if you want to show multiple routes then you can get all routes in a loop in the following statement
            //for route in unwrappedResponse.routes {}
        }
    }
    
    func routeMap() {
        
//        //create two dummy locations
//        let loc1 = CLLocationCoordinate2D.init(latitude: 51.513059, longitude: -0.091404)
//        let loc2 = CLLocationCoordinate2D.init(latitude: 51.516925, longitude: -0.089387)
//
////        51.513059, -0.091404
////        51.516925, -0.089387
        
        guard let currentLocation = self.currentLocation else {
            print("Current location not available")
            return
        }
        
        //find route
        showRouteOnMap(pickupCoordinate: currentLocation, destinationCoordinate: destination)
    }
    
    func addRadiusCircle(location: CLLocation){
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 500 as CLLocationDistance)
        self.mapView.addOverlay(circle)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.red
            circle.fillColor = UIColor.red.withAlphaComponent(0.1)
            circle.lineWidth = 1
            return circle
        }
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 5.0
        return renderer
    }
    
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location permission denied.")
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        locationManager.stopUpdatingLocation()
        self.currentLocation = userLocation.coordinate
        
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        
        let pin = MKPointAnnotation()
        pin.coordinate = userLocation.coordinate
        pin.title = "Current Location"
        mapView.addAnnotation(pin)
        
        routeMap()
        
        addRadiusCircle(location: userLocation)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("-----------------------------------------")
        print(error)
        print("-----------------------------------------")
    }
    
}

// MARK: - MKLocalSearchCompleterDelegate

extension ViewController: MKLocalSearchCompleterDelegate {
    
    func performSearch(query: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            
            if let e = error {
                print(e.localizedDescription)
                return
            }
            
            guard let response = response else { return }
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            if let location = response.mapItems.last {
                
                let pin = MKPointAnnotation()
                pin.title = location.name
                pin.coordinate = location.placemark.coordinate
                self.mapView.addAnnotation(pin)
                
                let region = MKCoordinateRegion(
                    center: location.placemark.coordinate,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                )
                
                self.mapView.setRegion(region, animated: true)
                
                // Code for making a circle on the searh locaton
                let searchLocation = CLLocation(latitude: location.placemark.coordinate.latitude, longitude: location.placemark.coordinate.longitude)
                self.addRadiusCircle(location: searchLocation)
                
            }
        }
    }
    
}

// MARK: - UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        performSearch(query: searchText)
        searchBar.resignFirstResponder()
    }
}
