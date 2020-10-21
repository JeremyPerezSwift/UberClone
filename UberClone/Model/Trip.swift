//
//  Trip.swift
//  UberClone
//
//  Created by Jérémy Perez on 21/10/2020.
//

import CoreLocation

struct Trip {
    
    var pickupCoordinates: CLLocationCoordinate2D!
    var destinationCoordinates: CLLocationCoordinate2D!
    let passengerUid: String!
    var driverUid: String?
    var state: TripState!
    
    init(passenger: String, dictionnary: [String: Any]) {
        self.passengerUid = passenger
        
        if let pickupC = dictionnary["pickupCoordinates"] as? NSArray {
            guard let lat = pickupC[0] as? CLLocationDegrees else { return }
            guard let long = pickupC[1] as? CLLocationDegrees else { return }
            self.pickupCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
        if let destinationC = dictionnary["destinationCoordinates"] as? NSArray {
            guard let lat = destinationC[0] as? CLLocationDegrees else { return }
            guard let long = destinationC[1] as? CLLocationDegrees else { return }
            self.destinationCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
        self.driverUid = dictionnary["driverUid"] as? String ?? ""
        
        if let state = dictionnary["state"] as? Int {
            self.state = TripState(rawValue: state)
        }
    }
    
}

enum TripState: Int {
    case requested
    case accepted
    case inProgress
    case completed
}
