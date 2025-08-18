//
//  AddMeetingNotesView.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/5/25.
//

import ChatBubble
import SwiftData
import SwiftUI

struct AddMeetingNotesView: View {

    let meeting: Meeting
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var intelligenceService: IntelligenceService?
    @State private var isGeneratingSummary = false
    @State private var showingError = false
    @State private var errorMessage = ""

    @State private var userResponse: String = ""
    @State private var chatMessages: [ChatMessage] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text("Ask your AI")
                .font(.title)
                .padding()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chatMessages, id: \.messageID) { message in
                        HStack {
                            if message.isUserMessage {
                                Spacer()
                                Text(message.content)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                            } else {
                                Text(message.content)
                                    .padding(10)
                                    .background(Color.orange.opacity(0.8))
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("AI is typing...")
                                .italic()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(minHeight: 180)

            Spacer()
        }
        .onAppear {
            if intelligenceService == nil {
                intelligenceService = IntelligenceService(meeting: meeting)
            }
        }
        .overlay(alignment: .bottom) {
            overlayTextField()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

extension AddMeetingNotesView {
    /// overlay for the textfield
    @ViewBuilder
    private func overlayTextField() -> some View {
        GlassEffectContainer {
            HStack {
                TextField(
                    "Ask a question or add a note",
                    text: $userResponse,
                    prompt: Text("Type your note here...")
                )
                .onSubmit {
                    sendMessage()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(userResponse.isEmpty ? .gray : .accentColor)
                        .padding(10)
                }
                
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .glassedEffect(in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private func sendMessage() {
        guard !userResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMessage = ChatMessage(
            messageID: UUID(),
            content: userResponse,
            timestamp: Date(),
            isUserMessage: true,
            meeting: meeting
        )
        chatMessages.append(userMessage)
        let question = userResponse
        userResponse = ""
        isLoading = true
        Task {
            do {
                if intelligenceService == nil {
                    intelligenceService = IntelligenceService(meeting: meeting)
                }
                try await intelligenceService?.suggestSummary()
                try await intelligenceService?.answerUserQuestion(question: question)
                if let aiMsg = intelligenceService?.aiChatMessage?.answer {
                    let aiMessage = ChatMessage(
                        messageID: UUID(),
                        content: aiMsg,
                        timestamp: Date(),
                        isUserMessage: false,
                        meeting: meeting
                    )
                    await MainActor.run {
                        chatMessages.append(aiMessage)
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "AI did not return a response."
                        showingError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {

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

    AddMeetingNotesView(meeting: meeting)
        .modelContainer(
            for: [Meeting.self, MeetingSummary.self, ActionItem.self, ChatMessage.self],
            inMemory: true
        )
}
