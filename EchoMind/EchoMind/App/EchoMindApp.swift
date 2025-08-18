//
//  EchoMindApp.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import SwiftUI
import SwiftData

@main
struct EchoMindApp: App {
    
    @State private var userPreferences = UserPreferencesService()
    @State private var permissions = PermissionService()
    @State private var recordingManager = RecordingStateManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !userPreferences.hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    HomeView()
                }
            }
            .environment(userPreferences)
            .environment(permissions)
            .recordingStateManager(recordingManager)
        }
        .modelContainer(for: [Meeting.self, MeetingSummary.self, ActionItem.self], inMemory : false)
    }
}
