//
//  MeetingDetailsView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import FoundationModels
import SwiftData
import SwiftUI

struct MeetingDetailsView: View {
    let meeting: Meeting
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var intelligenceService: IntelligenceService?
    @State private var isGeneratingSummary = false
    @State private var showingError = false
    @State private var errorMessage = ""

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingAddNotes = false

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section
                        headerSection

                        Divider()

                        // Content based on summary availability
                        if let summary = meeting.summary {
                            // Show summarized view
                            summarizedContentView(summary: summary)
                        } else {
                            // Show original/unsummarized view
                            originalContentView
                        }
                    }
                    .padding()
                    .padding(
                        .bottom,
                        (meeting.summary == nil && isAppleIntelligenceSupported)
                            ? 100 : 20
                    )  // Extra padding for floating button
                }

                // Floating Generate Summary Button (only if no summary exists and iOS 26+ is available)
                if meeting.summary == nil && isAppleIntelligenceSupported {
                    VStack {
                        Spacer()
                        generateSummaryButton
                    }
                }
            }
            .navigationTitle("Meeting Details")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    optionsMenu
                }
            }
            .onAppear {
                if isAppleIntelligenceSupported {
                    setupIntelligenceService()
                } else {
                    return  // Skip setup if AI is not supported
                }
            }
            .alert("Summary Generation Failed", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert(
                "Are you sure you want to delete this meeting?",
                isPresented: $isShowingDeleteConfirmation
            ) {
                Button("Yes", role: .destructive) {
                    deleteMeeting()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $isShowingAddNotes) {
                AddMeetingNotesView(meeting: meeting)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(meeting.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Label(
                    meeting.timestamp.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ),
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                // Status indicator
                if meeting.summary != nil {
                    Label("Summarized", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .clipShape(Capsule())
                } else if meeting.rawTranscript != nil {
                    Label("Ready to Summarize", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Label("Recording...", systemImage: "mic")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Original Content View (No Summary)
    @ViewBuilder
    private var originalContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Original Transcript")
                .font(.headline)
                .fontWeight(.semibold)

            if let transcript = meeting.rawTranscript {
                Text(transcript)
                    .font(.body)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)

                // Show note about AI requirements if not supported
                if !isAppleIntelligenceSupported {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("AI Summary generation requires iOS 26 or later")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 4)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("No transcript available yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(
                        "The transcript will appear here once the recording is processed."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                    if !isAppleIntelligenceSupported {
                        Text(
                            "Note: AI Summary generation requires iOS 26 or later."
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Summarized Content View
    @ViewBuilder
    private func summarizedContentView(summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Smart Summary Section
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Summary")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(summary.transcript)
                    .font(.body)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
            }

            // Action Items Section
            if !summary.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Action Items")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("\(summary.actionItems.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(summary.actionItems, id: \.action) {
                            actionItem in
                            actionItemView(actionItem)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Item View
    @ViewBuilder
    private func actionItemView(_ actionItem: ActionItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor(actionItem.priority))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(actionItem.action)
                    .font(.body)
                    .fontWeight(.medium)

                if let assignedTo = actionItem.assignedTo, !assignedTo.isEmpty {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Assigned to: \(assignedTo)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(actionItem.priority.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(priorityColor(actionItem.priority))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(actionItem.priority).opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    priorityColor(actionItem.priority).opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Options Menu
    @ViewBuilder
    private var optionsMenu: some View {
        Menu {
            Section("AI Actions") {
                Button {
                    if meeting.summary == nil {
                        generateSummary()
                    }
                } label: {
                    Label("Generate Summary", systemImage: "sparkles")
                }
                .disabled(
                    meeting.summary != nil || meeting.rawTranscript == nil
                        || !isAppleIntelligenceSupported
                )

                Button {
                    isShowingAddNotes = true
                } label: {
                    Label(
                        isAppleIntelligenceSupported ? "Ask AI" : "Add Notes",
                        systemImage: isAppleIntelligenceSupported
                            ? "bubbles.and.sparkles.fill" : "book.badge.plus"
                    )
                }

                Button {
                    // TODO: Implement add to calendar functionality
                } label: {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                }
            }

            Divider()

            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Floating Generate Summary Button
    @ViewBuilder
    private var generateSummaryButton: some View {
        HStack {
            Spacer()

            Button(action: generateSummary) {
                HStack(spacing: 8) {
                    if isGeneratingSummary {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(
                        isGeneratingSummary
                            ? "Generating..." : "Generate Summary"
                    )
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.blue)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .disabled(
                isGeneratingSummary || meeting.rawTranscript == nil
                    || !isAppleIntelligenceSupported
            )
            .animation(.easeInOut(duration: 0.2), value: isGeneratingSummary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    // MARK: - Helper Methods

    private func setupIntelligenceService() {
        intelligenceService = IntelligenceService(meeting: meeting)
    }

    private func deleteMeeting() {
        modelContext.delete(meeting)
        do {
            try modelContext.save()
            dismiss()  // Navigate back to the previous view
        } catch {
            errorMessage =
                "Failed to delete meeting: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func generateSummary() {
        guard isAppleIntelligenceSupported else {
            errorMessage = "AI Summary generation requires iOS 26 or later"
            showingError = true
            return
        }

        guard let intelligenceService = intelligenceService,
            meeting.rawTranscript != nil
        else {
            errorMessage = "No transcript available to summarize"
            showingError = true
            return
        }

        isGeneratingSummary = true

        Task {
            do {
                // Generate the AI summary
                try await intelligenceService.suggestSummary()

                // Save the meeting summary to the meeting object
                try await intelligenceService.saveMeetingSummary()

                // Update meeting title with AI-generated smart title
                // This permanently replaces the original user-provided title with the smarter AI version
                if let smartTitle = meeting.summary?.title, !smartTitle.isEmpty
                {
                    meeting.title = smartTitle
                }

                // Save all changes to SwiftData
                try modelContext.save()

                await MainActor.run {
                    isGeneratingSummary = false
                }
            } catch {
                // Check if this is a context size error and retry if so
                if error.localizedDescription.lowercased().contains(
                    "exceeded model context window size"
                ) {
                    generateSummary()
                } else {
                    // Handle other errors
                    await MainActor.run {
                        isGeneratingSummary = false
                        errorMessage =
                            "Failed to generate summary: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    // MARK: - iOS Version Check

    private var isAppleIntelligenceSupported: Bool {

        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            return true
        case .unavailable(.appleIntelligenceNotEnabled):
            return false
        case .unavailable(.deviceNotEligible):
            return false
        case .unavailable(.modelNotReady):
            return false
        default:
            return true
        }
    }
}

#Preview("No Summary - iOS 26+") {
    @Previewable @State var meeting = Meeting(
        id: UUID(),
        title: "Team Standup Meeting",
        timestamp: Date(),
        rawTranscript: AttributedString(
            "We discussed the quarterly goals and assigned tasks to team members. John will handle the frontend development while Sarah focuses on backend APIs."
        ),
        summary: nil,
        url: nil,
        isDone: false
    )

    MeetingDetailsView(meeting: meeting)
        .modelContainer(
            for: [
                Meeting.self, MeetingSummary.self, ActionItem.self,
                ChatMessage.self,
            ],
            inMemory: true
        )
}

#Preview("No Summary - Legacy iOS") {
    @Previewable @State var meeting = Meeting(
        id: UUID(),
        title: "Legacy Device Meeting",
        timestamp: Date(),
        rawTranscript: AttributedString(
            "This preview simulates how the view appears on devices running iOS versions prior to 26.0 where Apple Intelligence is not available."
        ),
        summary: nil,
        url: nil,
        isDone: false
    )

    MeetingDetailsView(meeting: meeting)
        .modelContainer(
            for: [
                Meeting.self, MeetingSummary.self, ActionItem.self,
                ChatMessage.self,
            ],
            inMemory: true
        )
}

#Preview("With Summary") {
    @Previewable @State var meeting = Meeting(
        id: UUID(),
        title: "Team Standup Meeting",
        timestamp: Date(),
        rawTranscript: AttributedString(
            "We discussed the quarterly goals and assigned tasks to team members."
        ),
        summary: MeetingSummary(
            title: "Q4 Team Planning & Task Assignment",
            transcript:
                "The team reviewed quarterly objectives and distributed responsibilities across frontend and backend development tracks.",
            actionItems: [
                ActionItem(
                    action: "Complete frontend user interface redesign",
                    assignedTo: "John",
                    priority: .high
                ),
                ActionItem(
                    action: "Develop backend API endpoints",
                    assignedTo: "Sarah",
                    priority: .medium
                ),
                ActionItem(
                    action: "Schedule follow-up review meeting",
                    assignedTo: nil,
                    priority: .low
                ),
            ]
        ),
        url: nil,
        isDone: false
    )

    MeetingDetailsView(meeting: meeting)
        .modelContainer(
            for: [
                Meeting.self, MeetingSummary.self, ActionItem.self,
                ChatMessage.self,
            ],
            inMemory: true
        )
}
