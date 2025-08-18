//
//  HomeView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import SwiftData
import SwiftUI

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.recordingStateManager) private var recordingManager
    @Environment(UserPreferencesService.self) private var userPreferences
    @Environment(PermissionService.self) private var permissions

    @State private var showFullTranscription = false
    @State private var isShowingAddMeeting: Bool = false
    @State private var showingSpeechModelDownload = false
    @State private var refreshTrigger = false


    private let headerHeight: CGFloat = 80

    @Query(sort: \Meeting.timestamp, order: .reverse) private var meetings: [Meeting]
    
    // Computed property that refreshes when trigger changes
    private var meetingsToDisplay: [Meeting] {
        _ = refreshTrigger // This forces the view to update when refreshTrigger changes
        return meetings
    }
    
    // Alternative approach: manually fetch meetings
    private func fetchMeetings() -> [Meeting] {
        let descriptor = FetchDescriptor<Meeting>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching meetings: \(error)")
            return []
        }
    }
    
    


    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Meetings section
                        meetingsSection
                    }
                    .padding(.top, headerHeight + 12)
                    .padding(.horizontal)
                }
                .overlay(alignment: .top) { headerView }
                
                // Floating Recording Toolbar
                .overlay(alignment: .bottom) {
                    if recordingManager.isRecording {
                        if let transcriber = recordingManager.transcriptionService {
                            FloatingRecordingToolbar(
                                isRecording: .constant(recordingManager.isRecording),
                                currentMeeting: .constant(recordingManager.currentMeeting),
                                transcriber: transcriber
                            )
                        } else {
                            // Audio-only recording toolbar (no transcription)
                            AudioOnlyRecordingToolbar(
                                isRecording: .constant(recordingManager.isRecording),
                                currentMeeting: .constant(recordingManager.currentMeeting)
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddMeeting) {
                AddMeetingView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSpeechModelDownload) {
                SpeechModelDownloadView {
                    // Retry recording after download
                    Task {
                        await recordingManager.retryRecordingAfterDownload()
                    }
                }
            }
            .onChange(of: recordingManager.showingSpeechModelDownload) { _, newValue in
                showingSpeechModelDownload = newValue
            }
            .onChange(of: showingSpeechModelDownload) { _, newValue in
                if !newValue {
                    recordingManager.showingSpeechModelDownload = false
                }
            }
//            .onAppear {
//                injectSampleDataIfNeeded()
//            }
//            .task {
//                // Delay slightly to ensure SwiftData is ready
//                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
//                injectSampleDataIfNeeded()
//            }
            .onAppear {
                Task {
                    await addExampleMeetingsAsync()
                }
            }
            .onChange(of: refreshTrigger) { _, _ in
                // This will trigger when refreshTrigger changes
                print("View refreshed, meetings count: \(meetings.count)")
            }
            
        }

    }
}

extension HomeView {
    @ViewBuilder
    private var headerView: some View {
        GlassEffectContainer {
            HStack {
                // Logo and greeting
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundStyle(.blue)

                    Text("Hi, \(userPreferences.username)!")
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .padding()

                Spacer()

                // Simple options
                HStack(spacing: 12) {
                    Button(action: {
                        refreshTrigger.toggle()
                        print("Manual refresh triggered, meetings count: \(meetings.count)")
                        let fetchedMeetings = fetchMeetings()
                        print("Manual fetch found \(fetchedMeetings.count) meetings")
                        for meeting in fetchedMeetings {
                            print("  - Fetched: \(meeting.title)")
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }

                    Button(action: {
                        isShowingAddMeeting.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }

                    Button(action: {
                        isShowingAddMeeting.toggle()
                    }) {
                        Image(systemName: "video.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                    .padding()
                }
            }

        }
        .padding(.horizontal)
        .glassEffect(.regular.interactive()
        )

    }

    @ViewBuilder
    private var meetingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Meetings")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if meetingsToDisplay.count > 3 {
                    Button("See All") {
                        // Navigate to all meetings
                    }
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                }
            }

            if meetingsToDisplay.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Meeting list
                ForEach(meetingsToDisplay.prefix(5)) { meeting in
                    NavigationLink(destination: MeetingDetailsView(meeting: meeting)) {
                        meetingRowView(meeting: meeting)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No meetings recorded yet")
                    .font(.headline)
                    .fontWeight(.medium)

                Text(
                    "Tap the + button to start recording your first meeting and let EchoMind create intelligent summaries with action items."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            }

            Button(action: {
                isShowingAddMeeting.toggle()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Record Your First Meeting")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func meetingRowView(meeting: Meeting) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(meeting.timestamp, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Status indicator
                HStack(spacing: 4) {
                    if let summary = meeting.summary {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(summary.actionItems.count) action items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if meeting.rawTranscript != nil {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.orange)
                        Text("Ready to summarize")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "mic")
                            .foregroundStyle(.blue)
                        Text("Recording...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )

    }

}

// MARK: - Helper Functions
extension HomeView {
    private func addExampleMeetings() {
        print("Adding example meetings...")
        
        // Check if we already have meetings
        let fetchDescriptor = FetchDescriptor<Meeting>()
        do {
            let existingMeetings = try modelContext.fetch(fetchDescriptor)
            if !existingMeetings.isEmpty {
                print("Meetings already exist, skipping injection")
                return
            }
        } catch {
            print("Error checking existing meetings: \(error)")
        }
        
        // Create and insert sample meetings
        let sampleMeetings = Meeting.createExampleMeetings()
        print("Created \(sampleMeetings.count) sample meetings")
        
        for meeting in sampleMeetings {
            modelContext.insert(meeting)
            print("Inserted: \(meeting.title)")
        }
        
        // Save to database with better error handling
        do {
            print("Attempting to save to database...")
            try modelContext.save()
            print("✅ Sample meetings saved successfully")
            
            // Wait a moment then verify
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.verifySavedMeetings()
            }
            
            // Force a refresh of the view
            DispatchQueue.main.async {
                self.refreshTrigger.toggle()
            }
        } catch {
            print("❌ Error saving sample meetings: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    private func verifySavedMeetings() {
        print("🔍 Verifying saved meetings...")
        let verifyDescriptor = FetchDescriptor<Meeting>()
        do {
            let savedMeetings = try modelContext.fetch(verifyDescriptor)
            print("🔍 Verification: Found \(savedMeetings.count) meetings in database")
            for meeting in savedMeetings {
                print("  - Saved: \(meeting.title)")
            }
        } catch {
            print("❌ Error verifying meetings: \(error)")
        }
    }
    
    private func addExampleMeetingsAsync() async {
        print("Adding example meetings (async)...")
        
        // Check if we already have meetings
        let fetchDescriptor = FetchDescriptor<Meeting>()
        do {
            let existingMeetings = try modelContext.fetch(fetchDescriptor)
            if !existingMeetings.isEmpty {
                print("Meetings already exist, skipping injection")
                return
            }
        } catch {
            print("Error checking existing meetings: \(error)")
        }
        
        // Create and insert sample meetings
        let sampleMeetings = Meeting.createExampleMeetings()
        print("Created \(sampleMeetings.count) sample meetings")
        
        await MainActor.run {
            for meeting in sampleMeetings {
                modelContext.insert(meeting)
                print("Inserted: \(meeting.title)")
            }
        }
        
        // Save to database
        do {
            print("Attempting to save to database (async)...")
            try modelContext.save()
            print("✅ Sample meetings saved successfully (async)")
            
            // Verify after a delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self.verifySavedMeetings()
                self.refreshTrigger.toggle()
            }
        } catch {
            print("❌ Error saving sample meetings (async): \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HomeView()
        .environment(UserPreferencesService())
        .environment(PermissionService())
        .modelContainer(
            for: [Meeting.self, MeetingSummary.self, ActionItem.self, ChatMessage.self],
            inMemory: false, isAutosaveEnabled: true
        )
}
