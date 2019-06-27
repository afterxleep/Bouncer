//
//  UserDataUserDefaultsService.swift
//  Bouncer
//
//  Created by Daniel Bernal on 3/25/19.
//  Copyright © 2019 Daniel Bernal. All rights reserved.
//

import Foundation

final class UserDataDefaultsService: UserDataService {
    
    var hasLaunchedApp: Bool {
        get { return getObject(key: "hasLaunchedApp", defaultValue: false) as! Bool }
        set(value) { setObject(key: "hasLaunchedApp", value: value) }
    }
    
    // - MARK : User Defaults Methods
    
    func getObject(key: String, defaultValue: Any) -> Any? {
        
        if(UserDefaults.standard.object(forKey: key) == nil) {
            return defaultValue
        }
        return UserDefaults.standard.object(forKey: key)
    }
    
    func setObject(key: String, value: Any?) {
        
        if value == nil {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(value, forKey: key)
        }
        
        UserDefaults.standard.synchronize()
    }

}
