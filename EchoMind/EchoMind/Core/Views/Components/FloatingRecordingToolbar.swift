//
//  FloatingRecordingToolbar.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import SwiftUI
import Foundation
import Combine

struct FloatingRecordingToolbar: View {
    @Binding var isRecording: Bool
    @Binding var currentMeeting: Meeting?
    @State private var showingTranscription = false
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    @State private var tapCount = 0
    
    // Live transcription from service
    var transcriber: SpokenWordTranscriber
    
    var body: some View {
        if isRecording {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Main floating toolbar
                    HStack(spacing: 12) {
                        // Recording indicator with pulse animation
                        recordingIndicator
                        
                        // Meeting info
                        meetingInfo
                        
                        // Waveform visualization
                        waveformView
                        
                        // Debug tap counter (remove in production)
                        if tapCount > 0 {
                            Text("\(tapCount)")
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .background(Circle().fill(.white))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .contentShape(Rectangle()) // Ensures entire area is tappable
                    .onTapGesture {
                        tapCount += 1
                        print("🎯 Toolbar tapped! Tap count: \(tapCount), Current showingTranscription: \(showingTranscription)")
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingTranscription = true
                        }
                        print("🎯 After tap, showingTranscription: \(showingTranscription)")
                    }
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingTranscription)
                    .onAppear {
                        print("🎯 FloatingRecordingToolbar appeared and is tappable")
                        withAnimation(.easeInOut(duration: 0.6)) {
                            pulseAnimation = true
                        }
                        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                            waveAnimation = true
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 100) // Account for tab bar space
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .sheet(isPresented: $showingTranscription) {
                LiveTranscriptionSheet(
                    transcriber: transcriber,
                    meeting: $currentMeeting,
                    isRecording: $isRecording
                )
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .onAppear {
                    print("📋 LiveTranscriptionSheet appeared!")
                }
            }
            .onChange(of: showingTranscription) { _, newValue in
                print("📋 showingTranscription changed to: \(newValue)")
            }
        }
    }
    
    // MARK: - Recording Indicator
    @ViewBuilder
    private var recordingIndicator: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0 : 1)
            
            // Inner recording dot
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
        }
        .frame(width: 20, height: 20)
    }
    
    // MARK: - Meeting Info
    @ViewBuilder
    private var meetingInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recording")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            if let meeting = currentMeeting {
                Text(meeting.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Waveform Visualization
    @ViewBuilder
    private var waveformView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.blue.opacity(0.7))
                    .frame(width: 2)
                    .frame(height: waveHeights[index])
                    .animation(
                        .easeInOut(duration: 0.5)
                        .delay(Double(index) * 0.1)
                        .repeatForever(autoreverses: true),
                        value: waveAnimation
                    )
            }
        }
        .frame(width: 20, height: 16)
    }
    
    // Dynamic wave heights for animation
    private var waveHeights: [CGFloat] {
        waveAnimation ? [4, 8, 12, 6, 10] : [2, 4, 6, 3, 5]
    }
}

// MARK: - Live Transcription Sheet
struct LiveTranscriptionSheet: View {
    var transcriber: SpokenWordTranscriber
    @Binding var meeting: Meeting?
    @Binding var isRecording: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recordingStateManager) private var recordingManager
    
    // Timer for real-time duration updates
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with meeting info
                headerSection
                
                Divider()
                
                // Live transcription content
                transcriptionContent
                
                // Recording controls
                controlsSection
            }
            .navigationTitle("Live Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("🔴 Done button tapped in transcription sheet")
                        dismiss()
                    }
                }
            }
            .onAppear {
                print("📋 LiveTranscriptionSheet body appeared!")
                print("📋 Current transcriber: \(transcriber)")
                print("📋 Meeting: \(meeting?.title ?? "No meeting")")
                print("📋 Is recording: \(isRecording)")
                currentTime = Date()
            }
            .onReceive(timer) { time in
                currentTime = time
                // This updates every second, forcing UI refresh for duration display
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Recording status
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    
                    Text("Recording in progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Meeting title
                if let meeting = meeting {
                    Text(meeting.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Real-time stats
            HStack(spacing: 20) {
                statView(title: "Duration", value: recordingDuration)
                statView(title: "Words", value: wordCount)
                statView(title: "Status", value: "Active")
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Transcription Content
    @ViewBuilder
    private var transcriptionContent: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 16) {
                    // Finalized transcript
                    if !transcriber.finalizedTranscript.description.isEmpty {
                        Text("Finalized Transcript:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(transcriber.finalizedTranscript)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    
                    // Live/volatile transcript
                    if !transcriber.volatileTranscript.description.isEmpty {
                        Text("Live Transcript:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(transcriber.volatileTranscript)
                            .font(.body)
                            .contentTransition(.opacity)
                            .foregroundStyle(.secondary)
                            .opacity(0.8)
                            .id("liveTranscript")
                    }
                    
                    // Empty state
                    if transcriber.finalizedTranscript.description.isEmpty && transcriber.volatileTranscript.description.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            
                            Text("Listening for speech...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Start speaking to see live transcription appear here")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                            
                            Text("If you're in the simulator, speech recognition may not work.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding()
                .onChange(of: transcriber.volatileTranscript) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("liveTranscript", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Controls Section  
    @ViewBuilder
    private var controlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Stop recording button
                Button(action: {
                    // Stop recording action
                    print("🔴 Stop recording button tapped")
                    Task {
                        do {
                            try await recordingManager.stopRecording()
                            print("🔴 Recording stopped successfully")
                        } catch {
                            print("🔴 Failed to stop recording: \(error)")
                        }
                    }
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Recording")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.red)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Pause/Resume button
                Button(action: {
                    print("⏸️ Pause/Resume button tapped, isPaused: \(recordingManager.isPaused)")
                    Task {
                        do {
                            if recordingManager.isPaused {
                                try recordingManager.resumeRecording()
                                print("▶️ Recording resumed")
                            } else {
                                recordingManager.pauseRecording()
                                print("⏸️ Recording paused")
                            }
                        } catch {
                            print("⏸️ Failed to toggle recording: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: recordingManager.isPaused ? "play.fill" : "pause.fill")
                        Text(recordingManager.isPaused ? "Resume" : "Pause")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func statView(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    private var recordingDuration: String {
        // Use the recording manager's duration which updates in real-time
        let duration = recordingManager.recordingDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let formatted = String(format: "%02d:%02d", minutes, seconds)
        
        return formatted
    }
    
    private var wordCount: String {
        let finalWords = transcriber.finalizedTranscript.description.split(separator: " ").count
        let volatileWords = transcriber.volatileTranscript.description.split(separator: " ").count
        return "\(finalWords + volatileWords)"
    }
}

// MARK: - Audio-Only Recording Toolbar (No Transcription)
struct AudioOnlyRecordingToolbar: View {
    @Binding var isRecording: Bool
    @Binding var currentMeeting: Meeting?
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    
    var body: some View {
        if isRecording {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Main floating toolbar
                    HStack(spacing: 12) {
                        // Recording indicator with pulse animation
                        recordingIndicator
                        
                        // Meeting info
                        meetingInfo
                        
                        // Audio-only indicator
                        audioOnlyIndicator
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            pulseAnimation = true
                        }
                        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                            waveAnimation = true
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 100) // Account for tab bar space
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Recording Indicator
    @ViewBuilder
    private var recordingIndicator: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0 : 1)
            
            // Inner recording dot
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
        }
        .frame(width: 20, height: 20)
    }
    
    // MARK: - Meeting Info
    @ViewBuilder
    private var meetingInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recording (Audio Only)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            if let meeting = currentMeeting {
                Text(meeting.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Audio Only Indicator
    @ViewBuilder
    private var audioOnlyIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "mic.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            
            Text("Audio")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("With Transcription") {
    @Previewable @State var isRecording = true
    @Previewable @State var currentMeeting: Meeting? = Meeting(
        id: UUID(),
        title: "Team Standup",
        timestamp: Date()
    )
    
    let transcriber = SpokenWordTranscriber(meeting: .constant(currentMeeting!))
    
    return FloatingRecordingToolbar(
        isRecording: $isRecording,
        currentMeeting: $currentMeeting,
        transcriber: transcriber
    )
}

#Preview("Audio Only") {
    @Previewable @State var isRecording = true
    @Previewable @State var currentMeeting: Meeting? = Meeting(
        id: UUID(),
        title: "Simulator Test",
        timestamp: Date()
    )
    
    return AudioOnlyRecordingToolbar(
        isRecording: $isRecording,
        currentMeeting: $currentMeeting
    )
}
