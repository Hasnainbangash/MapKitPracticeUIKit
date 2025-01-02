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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        searchBar.delegate = self
        
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
