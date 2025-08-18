//
//  RecordingStateManager.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

@Observable
final class RecordingStateManager {
    // MARK: - Published Properties
    var isRecording: Bool = false
    var isPaused: Bool = false
    var currentMeeting: Meeting? = nil
    var recordingService: RecorderService? = nil
    var transcriptionService: SpokenWordTranscriber? = nil
    
    // Recording session info
    var recordingStartTime: Date? = nil
    var recordingDuration: TimeInterval = 0
    
    // Speech model state
    var showingSpeechModelDownload = false
    var lastRecordingError: Error? = nil
    
    // Timer for updating duration
    private var durationTimer: Timer? = nil
    
    // MARK: - Shared Instance
    static let shared = RecordingStateManager()
    
    private init() {}
    
    // MARK: - Recording Control Methods
    
    /// Start a new recording session
    func startRecording(meeting: Meeting) async throws {
        guard !isRecording else { 
            print("Recording already in progress")
            return 
        }
        
        print("Starting recording for meeting: \(meeting.title)")
        
        do {
            // Create services
            let transcriber = SpokenWordTranscriber(meeting: .constant(meeting))
            let recorder = RecorderService(transcriber: transcriber, meeting: .constant(meeting))
            
            // Store references
            self.currentMeeting = meeting
            self.transcriptionService = transcriber
            self.recordingService = recorder
            self.recordingStartTime = Date()
            self.isRecording = true
            
            // Start duration timer
            startDurationTimer()
            
            // Start recording
            try await recorder.startRecording()
            print("Recording started successfully")
        } catch {
            print("Failed to start recording: \(error)")
            
            // Handle specific error types
            if let transcriptionError = error as? TranscriptionError,
               transcriptionError == .localeNotSupported {
                print("No speech recognition locales available")
                
                // Check if we're in simulator
                if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
                    print("Running in simulator - attempting audio-only recording")
                    await tryAudioOnlyRecording(meeting: meeting)
                } else {
                    print("On device - showing download UI")
                    await MainActor.run {
                        self.showingSpeechModelDownload = true
                        self.lastRecordingError = error
                    }
                }
            }
            
            // Clean up on failure if not handled above
            if !isRecording {
                self.currentMeeting = nil
                self.transcriptionService = nil
                self.recordingService = nil
                self.recordingStartTime = nil
                stopDurationTimer()
            }
            
            // Only throw if we couldn't handle it
            if !isRecording {
                throw error
            }
        }
    }
    
    /// Attempt audio-only recording without transcription (for simulator)
    private func tryAudioOnlyRecording(meeting: Meeting) async {
        do {
            print("Attempting audio-only recording without transcription")
            
            // Create a simplified transcriber that doesn't actually transcribe
            let dummyTranscriber = SpokenWordTranscriber(meeting: .constant(meeting))
            let recorder = RecorderService(transcriber: dummyTranscriber, meeting: .constant(meeting))
            
            // Store references (but mark transcription as unavailable)
            self.currentMeeting = meeting
            self.transcriptionService = nil // No transcription available
            self.recordingService = recorder
            self.recordingStartTime = Date()
            self.isRecording = true
            
            // Start duration timer
            startDurationTimer()
            
            // Start just the audio recording part
            try setUpAudioSession()
            print("Audio-only recording started (no transcription)")
            
        } catch {
            print("Failed to start even audio-only recording: \(error)")
            await MainActor.run {
                self.isRecording = false
                self.currentMeeting = nil
                self.transcriptionService = nil
                self.recordingService = nil
                self.recordingStartTime = nil
                self.stopDurationTimer()
            }
        }
    }
    
    private func setUpAudioSession() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        #endif
    }
    
    /// Stop the current recording session
    func stopRecording() async throws {
        guard isRecording, let recorder = recordingService else { return }
        
        // Stop recording
        try await recorder.stopRecording()
        
        // Clean up
        stopDurationTimer()
        isRecording = false
        isPaused = false
        recordingStartTime = nil
        recordingDuration = 0
        
        // Keep references for a moment to allow UI cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentMeeting = nil
            self.recordingService = nil
            self.transcriptionService = nil
        }
    }
    
    /// Pause the current recording
    func pauseRecording() {
        guard isRecording && !isPaused, let recorder = recordingService else { return }
        print("⏸️ Pausing recording...")
        recorder.pauseRecording()
        isPaused = true
        stopDurationTimer()
    }
    
    /// Resume the current recording
    func resumeRecording() throws {
        guard isRecording && isPaused, let recorder = recordingService else { return }
        print("▶️ Resuming recording...")
        try recorder.resumeRecording()
        isPaused = false
        startDurationTimer()
    }
    
    // MARK: - Duration Management
    
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    private func updateDuration() {
        guard let startTime = recordingStartTime else { 
            print("⏱️ No start time for duration update")
            return 
        }
        let newDuration = Date().timeIntervalSince(startTime)
        recordingDuration = newDuration
        
    }
    
    // MARK: - Computed Properties
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var wordCount: Int {
        guard let transcriber = transcriptionService else { return 0 }
        let finalWords = transcriber.finalizedTranscript.description.split(separator: " ").count
        let volatileWords = transcriber.volatileTranscript.description.split(separator: " ").count
        return finalWords + volatileWords
    }
    
    // MARK: - Speech Model Management
    
    /// Retry recording after downloading speech model
    func retryRecordingAfterDownload() async {
        guard let meeting = currentMeeting else { return }
        
        // Reset error state
        lastRecordingError = nil
        showingSpeechModelDownload = false
        
        // Try recording again
        do {
            try await startRecording(meeting: meeting)
        } catch {
            print("Failed to start recording after download: \(error)")
            lastRecordingError = error
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopDurationTimer()
    }
}

// MARK: - SwiftUI Environment Extension
extension EnvironmentValues {
    @Entry var recordingStateManager: RecordingStateManager = .shared
}

extension View {
    func recordingStateManager(_ manager: RecordingStateManager) -> some View {
        environment(\.recordingStateManager, manager)
    }
}