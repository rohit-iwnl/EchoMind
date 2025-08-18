//
//  PermissionService.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import Foundation
import AVFoundation
import Speech
import Observation


@Observable
final class PermissionService {
    var microphonePermissionStatus: AVAudioApplication.recordPermission = .undetermined
    var speechRecognitionPermissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    init() {
        checkInitialPermissions()
    }
    
    private func checkInitialPermissions() {
        microphonePermissionStatus = AVAudioApplication.shared.recordPermission
        speechRecognitionPermissionStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphonePermissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.speechRecognitionPermissionStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    var allPermissionsGranted : Bool {
        return microphonePermissionStatus == .granted && speechRecognitionPermissionStatus == .authorized
    }
}

