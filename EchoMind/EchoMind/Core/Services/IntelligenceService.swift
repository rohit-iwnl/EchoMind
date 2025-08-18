//
//  IntelligenceService.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import Foundation
import FoundationModels
import SwiftData
import SwiftUI

@Observable
@MainActor
final class IntelligenceService {
    private(set) var meetingDetails: GenerableMeetingDetails?
    private let session: LanguageModelSession

    private(set) var aiChatMessage: GenerableChatMessage.PartiallyGenerated?

    var meeting: Meeting

    init(meeting: Meeting) {
        self.meeting = meeting
        self.aiChatMessage = nil
        self.session = LanguageModelSession {
            """
            You are an helpful AI assistant designed to help summarize meeting transcripts and generate action items.
            Your task is to analyze the provided meeting transcript and extract key information such as:
            - A concise title for the meeting
            - A summary of the meeting
            - Action items with details such as action item title, assigned person, and priority
            """
        }

        session.prewarm()
    }

    func suggestSummary() async throws {
        let response = try await session.respond(
            generating: GenerableMeetingDetails.self
        ) {
            """

            Here is the meeting title that was given by the user:
            \(meeting.title)

            Here is the meeting transcript for your analysis:
            \(String(describing: meeting.rawTranscript))

            Please generate a concise title, summary, and action items based on the transcript.
            """
        }

        self.meetingDetails = response.content
    }

    func answerUserQuestion(question: String) async throws {

        guard let meetingDetails = meetingDetails else {
            throw NSError(
                domain: "IntelligenceServiceError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Meeting details not available"
                ]
            )
        }

        let stream = session.streamResponse(
            generating: GenerableChatMessage.self
        ) {
            """
                You are an AI assistant designed to answer user questions based on meeting transcripts.
                
                The user has asked the following question:
                \(question)

                Here is the meeting details you have:
                Title: \(meetingDetails.smartTitle)
                Summary: \(meetingDetails.smartTranscript)
                Action Items: \(meetingDetails.actionItems.map { "\($0.actionItemTitle) assigned to \($0.assignedTo) with priority \($0.priority)" }.joined(separator: ", "))


                Please answer the user's question based on the provided meeting details.
            """
        }
        
        
        for try await chunk in stream {
            aiChatMessage = chunk
        }
    }

    func saveMeetingSummary() async throws {
        if let meetingDetails = meetingDetails {
            meeting.summary = MeetingSummary(
                title: meetingDetails.smartTitle,
                transcript: meetingDetails.smartTranscript,
                actionItems: meetingDetails.actionItems.map {
                    ActionItem(
                        action: $0.actionItemTitle,
                        assignedTo: $0.assignedTo,
                        priority: mapPriority($0.priority)
                    )
                }
            )
        } else {
            throw NSError(
                domain: "IntelligenceServiceError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Meeting details not available"
                ]
            )
        }
    }

    private func mapPriority(_ priority: GenerablePriority) -> Priority {
        switch priority {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}
