//
//  ViewController.swift
//  MKMapView
//
//  Created by Миша Вашкевич on 23.05.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    // MARK: Properties
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    private var path: [MKPlacemark] = []
    
    // MARK: Subviews
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.mapType = .hybrid
        map.showsUserLocation = true
        map.showsUserTrackingButton = true
        map.delegate = self
        let longTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapTapped))
        longTapGestureRecognizer.minimumPressDuration = 0.3
        map.addGestureRecognizer(longTapGestureRecognizer)
        return map
    }()
    private lazy var creatRouteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Построить маршрут", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: #selector(creatRoute), for: .touchUpInside)
        return button
    }()
    private lazy var removeAnnotationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Удалить метку", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: #selector(removeAnnotation), for: .touchUpInside)
        return button
    }()
    private lazy var removeDirectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Удалить машрут", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.isHidden = true
        button.addTarget(self, action: #selector(removeDirection), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupView()
    }

    private func setupView() {
        
        view.addSubview(mapView)
        view.addSubview(creatRouteButton)
        view.addSubview(removeAnnotationButton)
        view.addSubview(removeDirectionButton)
        locationManager.requestWhenInUseAuthorization()
        
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            creatRouteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            creatRouteButton.widthAnchor.constraint(equalToConstant: 160),
            creatRouteButton.heightAnchor.constraint(equalToConstant: 50),
            creatRouteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            removeAnnotationButton.bottomAnchor.constraint(equalTo: creatRouteButton.topAnchor, constant: -10),
            removeAnnotationButton.widthAnchor.constraint(equalToConstant: 160),
            removeAnnotationButton.heightAnchor.constraint(equalToConstant: 50),
            removeAnnotationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            removeDirectionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            removeDirectionButton.widthAnchor.constraint(equalToConstant: 160),
            removeDirectionButton.heightAnchor.constraint(equalToConstant: 50),
            removeDirectionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
        ])
        
    }
    
    @objc func mapTapped(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let point = sender.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            createPointAnnotation(coordinate: coordinate)
        }
    }
    
    @objc func removeAnnotation() {
        removeAnnotations()
        creatRouteButton.isHidden = true
        removeAnnotationButton.isHidden = true
    }
    
    @objc func creatRoute() {
        removeAnnotationButton.isHidden = true
        creatRouteButton.isHidden = true
        removeDirectionButton.isHidden = false
        createDerection(path: path)
    }
    
    @objc func removeDirection() {
        removeDirectionButton.isHidden = true
        removeAnnotations()
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    
    private func createPointAnnotation(coordinate: CLLocationCoordinate2D) {
        if mapView.annotations.count > 1 {
            return
        }
        
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        path = []
        locationManager.startUpdatingLocation()
        getAddresFromCoordinates(coordinate: coordinate) {[weak self] title in
            pointAnnotation.title = title
            self?.mapView.addAnnotation(pointAnnotation)
            self?.creatRouteButton.isHidden = false
            self?.removeAnnotationButton.isHidden = false
            
        }
    }
    
    private func removeAnnotations() {
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
    }
    
    private func getAddresFromCoordinates(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) {[weak self] placemarks, error in
            if let error = error {
                print(error)
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            guard let location = placemark.location else { return }
            self?.path.append(MKPlacemark(coordinate: location.coordinate))
            completion(placemark.name)
            
        }
    }
    
    private func createDerection(path: [MKPlacemark]) {
        let sourceMapItem = MKMapItem(placemark: path[0])
        let destinationMapItem = MKMapItem(placemark: path[1])
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        directionsRequest.transportType = .walking
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { response, error in
            guard let response = response else {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                return
            }
            
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
        
    }
}
    // MARK: CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        guard let userLocation = locations.first else { return }
        let userPlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        path.insert(userPlacemark, at: 0)
    }
    
}

    // MARK: MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
