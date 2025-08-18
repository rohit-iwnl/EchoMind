//
//  OnboardingView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import Foundation
import SwiftUI

struct OnboardingView: View {

    @Environment(UserPreferencesService.self) private var userPreferences
    @Environment(PermissionService.self) private var permissions

    @State private var userName: String = ""
    @State private var isRequestingPermissions: Bool = false
    @State private var permissionAlertPresented: Bool = false
    @State private var permissionAlertMessage: String = ""

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("Welcome to EchoMind")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("AI-powered meeting summaries, right on your device")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                TextField("What's your name?", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .submitLabel(.done)
                    .tint(.accentColor)

                // Show permission button only after name is entered
                if !userName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                {
                    VStack(spacing: 12) {
                        // Permission request button
                        if !permissions.allPermissionsGranted {
                            Button(action: requestPermissions) {
                                HStack {
                                    if isRequestingPermissions {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "mic.fill")
                                    }
                                    Text(
                                        isRequestingPermissions
                                            ? "Setting up..."
                                            : "Enable Microphone & Speech"
                                    )
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isRequestingPermissions)
                        }

                        // Get started button
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    
                }
            }
            .padding(.horizontal)

            Spacer()

            // Privacy disclaimer
            
            HStack{
                
                Spacer()
                
                Text("Fully private. All processing happens on-device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .padding()
        .alert("Permission Denied", isPresented: $permissionAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(permissionAlertMessage)
        }
    }

    private func requestPermissions() {
        isRequestingPermissions = true

        Task {
            // Request permissions sequentially
            let micGranted = await permissions.requestMicrophonePermission()
            let speechGranted =
                await permissions.requestSpeechRecognitionPermission()

            await MainActor.run {
                isRequestingPermissions = false
            }

            // Optional: Show feedback if permissions were denied
            if !micGranted || !speechGranted {
                permissionAlertMessage = "Please enable microphone and speech recognition permissions in Settings to use EchoMind."
                permissionAlertPresented = true
            }
        }
    }

    private func completeOnboarding() {
        let trimmedName = userName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        // Update user preferences - this will trigger the app to show the home screen
        userPreferences.username = trimmedName
        userPreferences.hasCompletedOnboarding = true
    }

}

#Preview {
    OnboardingView()
        .environment(UserPreferencesService())
        .environment(PermissionService())
}
