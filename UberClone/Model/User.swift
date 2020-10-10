//
//  User.swift
//  UberClone
//
//  Created by Jérémy Perez on 09/10/2020.
//

import CoreLocation

struct User {
    
    let fullname: String
    let email: String
    let accountType: Int
    var location: CLLocation?
    
    init(dictionary: [String: Any]) {
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
    
}
