//
//  AddMeetingView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import SwiftData
import SwiftUI

struct AddMeetingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.recordingStateManager) private var recordingManager
    @Environment(UserPreferencesService.self) private var userPreferences
    @Environment(PermissionService.self) private var permissions
    
    var onStartRecording: ((Meeting) -> Void)?


    @State private var meetingTitle: String = ""
    @State private var meetingTimestamp: Date = Date()
    @State private var showingPermissionAlert = false

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            // Header with dismiss button
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("Record New Meeting")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Invisible spacer for balance
                Button("Cancel") {
                    dismiss()
                }
                .opacity(0)
                .disabled(true)
            }

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)

                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Title")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter meeting title...", text: $meetingTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .submitLabel(.done)
                }

                HStack {
                    Text("Meeting Date & Time")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    DatePicker(
                        "Meeting Date",
                        selection: $meetingTimestamp,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()

                }
            }

            if !permissions.allPermissionsGranted {
                Button("Grant Microphone & Speech Permissions") {
                    requestPermissions()
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Spacer()

            Button(action: startRecording) {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .font(.title3)
                    Text("Start Recording")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                        ? .gray : .red,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(
                meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            )
            .buttonStyle(.plain)
        }
        .padding()
        .alert("Permissions Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "EchoMind needs microphone and speech recognition permissions to record and transcribe your meetings."
            )
        }
        .padding()
    }
}

extension AddMeetingView {
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse.byLayer, options: .repeating)

            VStack(spacing: 6) {
                Text("Record New Meeting")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("EchoMind will transcribe and summarize automatically")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top)
    }

    private func requestPermissions() {
        Task {
            await permissions.requestMicrophonePermission()
            await permissions.requestSpeechRecognitionPermission()

            if !permissions.allPermissionsGranted {
                showingPermissionAlert = true
            }
        }
    }

    private func startRecording() {
        let trimmedTitle = meetingTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedTitle.isEmpty else { return }

        if !permissions.allPermissionsGranted {
            showingPermissionAlert = true
            return
        }

        // Create new meeting
        let newMeeting = Meeting(
            id: .init(),
            title: trimmedTitle,
            timestamp: .now
        )
        modelContext.insert(newMeeting)
        
        try? modelContext.save()

        // Start recording with the recording manager
        Task {
            do {
                try await recordingManager.startRecording(meeting: newMeeting)
            } catch {
                print("Failed to start recording: \(error)")
            }
        }

        // Dismiss sheet
        dismiss()
        
        onStartRecording?(newMeeting)
    }

}

#Preview {
    AddMeetingView()
        .environment(UserPreferencesService())
        .environment(PermissionService())
        .modelContainer(
            for: [Meeting.self, MeetingSummary.self, ActionItem.self],
            inMemory: true
        )
}
