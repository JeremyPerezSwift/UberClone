//
//  Service.swift
//  UberClone
//
//  Created by Jérémy Perez on 09/10/2020.
//

import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionnary = snapshot.value as? [String: AnyObject] else { return }
            guard let fullname = dictionnary["fullname"] as? String else { return }
            print("DEBUG: User fullname is: \(fullname)")
        }
    }
}
