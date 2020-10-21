//
//  HomeController.swift
//  UberClone
//
//  Created by Jérémy Perez on 08/10/2020.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"

enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private let rideActionView = RideActionView()
    
    private let inputActivationView = LocationInputActivationView()
    private var locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private var route: MKRoute?
    
    private var actionButtonConfig = ActionButtonConfiguration()
    
    private var user: User? {
        didSet {
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
            } else {
                print("DEBUG: User is driver..")
            }
        }
    }
    
    let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "menu").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .mainBlueTint
//        signOut()
        checkIfUserIsLoggedIn()
        locationManagerAuthorization()
    }
    
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
    
        case .showMenu:
            print("DEBUG: Handle show menu")
        case .dismissActionView:
            print("DEBUG: Handle dismissal")
            
            removeAnnotationAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.presentRideActionView(shouldShow: false)
            }
        }
    }
    
    // MARK: - API
    
    func fetchUserData() {
        Service.shared.fetchUserData { (user) in
            self.user = user
        }
    }
    
    func fetchDrivers() {
        guard let location = locationManager?.location else { return }
        
        Service.shared.fetchDrivers(location: location, withRadius: 10) { (driver) in

            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)

            var driverIsVisible: Bool {
                return self.mapView.annotations.contains { (annotationP) -> Bool in
                    guard let driverAnnotation = annotationP as? DriverAnnotation else { return false }
                    if driverAnnotation.uid == driver.uid {
                        print("DEBUG: Handle update driver position")
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }

            print(!driverIsVisible)

            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            print("DEBUG: User not logged in ...")
            
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            configure()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } catch {
            print("DEBUG: Error sign out ...")
        }
    }
    
    // MARK: - Helpers
    
    func configure() {
        configureUI()
        fetchUserData()
    }
    
    func configureUI() {
        configureMapView()
        
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16, width: 30, height: 30)
        
        configureTableView()
    }
    
    func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(width: view.frame.width - 70, height: 50)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 1.5) {
            self.inputActivationView.alpha = 1
        }
    }
    
    func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "menu").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "left-arrow").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    func configureMapView() {
        locationInputView.delegate = self
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        mapView.delegate = self
    }
    
    func configureLocationInputView() {
        view.addSubview(locationInputView)
        
        let height = view.frame.height / 4
        
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: height)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = (self.view.frame.height / 4)
            }
        }

    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - (view.frame.height / 4)
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
//        tableView.backgroundColor = .mainBlueTint
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
        
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.frame =  CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 300)
    }
    
    func presentRideActionView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height - 300
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
}

// MARK: - Map Helper Functions

private extension HomeController {
    func search(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else { return }
            
            response.mapItems.forEach { (item) in
                results.append(item.placemark)
            }
            
            completion(results)
        }
    }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 3
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, error) in
            guard let response = response else { return }
            self.route =  response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationAndOverlays() {
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
}

// MARK: - LocationServices

extension HomeController {
    
    func locationManagerAuthorization() {
        
        switch CLLocationManager().authorizationStatus {
        case .notDetermined:
            print("DEBUG: Not determined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth always")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Auth when in use")
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
}
 
// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        print("DEBUG: Handle present location input view ...")
        
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        search(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { (_) in
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
            return cell
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView { (_) in
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) })
            self.mapView.zoomToFit(annotations: annotations)
            
            self.presentRideActionView(shouldShow: true)
            self.rideActionView.destination = selectedPlacemark
            self.rideActionView.delegate = self
        }
    }
}

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (err, ref) in
            if let error = err {
                print("DEBUG: Failed to upload trip with error \(error)")
                return
            }
            
            print("DEBUG: Did upload trip successfully")
        }
    }
}
