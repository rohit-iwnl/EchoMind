//
//  MeetingDetails.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/2/25.
//

import Foundation
import FoundationModels

/// Represents the details of a meeting.
///
/// This model contains information about a meeting, including its title, short summary, and a list of action items discussed during the meeting.
///
///

enum Priority: String, Codable {
    case high
    case medium
    case low
}

@Generable
struct ActionItem : Equatable{
    @Guide(description: "The action item to be completed.")
    let action : String
    @Guide(description: "The person responsible for completing the action item.")
    let responsiblePerson : String
    @Guide(description: "The priority level for completing the action item. where high is most urgent, medium is moderately urgent, and low is least urgent.")
    let priority : Priority
}

@Generable
struct MeetingDetails : Equatable {
    /// The unique identifier for the meeting.
    let id: UUID
    
    @Guide(description: "The title of the meeting.")
    let title : String
    
    @Guide(description: "A brief summary of the meeting's content.")
    let shortSummary: String
    
    @Guide(description: "A list of action items discussed during the meeting.")
    let actionItems : [ActionItem]
}
