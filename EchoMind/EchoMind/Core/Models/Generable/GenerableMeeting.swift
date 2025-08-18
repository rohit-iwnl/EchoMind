//
//  GenerableMeeting.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import Foundation
import FoundationModels

@Generable
enum GenerablePriority {
    case high
    case medium
    case low
}


@Generable
struct GenerableMeetingDetails : Equatable {
    @Guide(description: "Summaize the meeting details in a concise manner in less than 10 words.")
    let smartTitle : String
    
    @Guide(description: "Generate a concise summary of the meeting, focusing on key points and decisions made.")
    let smartTranscript : String
    
    
    @Guide(description: "Generate a list of key discussion points from the meeting transcript, highlighting important topics and decisions.")
    let actionItems : [GenerableActionItems]
}

@Generable
struct GenerableActionItems : Equatable {
    @Guide(description: "Generate a list of action items from the meeting transcript, focusing on tasks assigned and their priorities.")
    let actionItemTitle : String
    
    @Guide(description: "Generate the name of the person assigned to the action item, if applicable.")
    let assignedTo : String
    
    @Guide(description: "Generate the priority of the action item based on its urgency and importance.")
    let priority : GenerablePriority
}
