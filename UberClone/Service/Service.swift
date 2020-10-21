//
//  Service.swift
//  UberClone
//
//  Created by Jérémy Perez on 09/10/2020.
//

import Firebase
import GeoFire

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionnary = snapshot.value as? [String: AnyObject] else { return }
            
            let uid = snapshot.key
            
            let user = User(uid: uid, dictionary: dictionnary)
            completion(user)
        }
    }
    
    func fetchUserData2(uid: String, completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionnary = snapshot.value as? [String: AnyObject] else { return }
            
            let uid = snapshot.key
            
            let user = User(uid: uid, dictionary: dictionnary)
            completion(user)
        }
    }
    
    func fetchDrivers(location: CLLocation, withRadius: Double, completion: @escaping(User) -> Void) {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot) in
            let geoFireQuery = geofire.query(at: location, withRadius: withRadius)

            geoFireQuery.observe(.keyEntered, with: { (uid, location) in
                self.fetchUserData2(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    
                    completion(driver)
                }
            })
        }
    }
    
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D, _ destinationCoordinates: CLLocationCoordinate2D, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = ["pickupCoordinates": pickupArray, "destinationCoordinates": destinationArray, "state": TripState.requested.rawValue] as [String : Any]
        
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
        
        
    }
    
    
    
}
