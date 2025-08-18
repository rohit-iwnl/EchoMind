//
//  UserPreferencesService.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import Foundation

@Observable
final class UserPreferencesService {
    private let userDefaults = UserDefaults.standard
    private let userNameKey = "userName"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    
    var username : String {
        get{
            return userDefaults.string(forKey: userNameKey) ?? ""
        }
        set{
            userDefaults.set(newValue, forKey: userNameKey)
            
            if !newValue.isEmpty {
                hasCompletedOnboarding = true
            }
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            return userDefaults.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            userDefaults.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
}
