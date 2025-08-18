//
//  MeetingSummary.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import Foundation
import SwiftData
import FoundationModels

enum Priority: String, Codable {
    case high
    case medium
    case low
}

@Model
final class MeetingSummary {
    var title : String
    @Attribute(.externalStorage) var transcript : String
    
    @Relationship(deleteRule: .cascade)
    var actionItems : [ActionItem] = []
    
    init(title: String, transcript: String, actionItems: [ActionItem]) {
        self.title = title
        self.transcript = transcript
        self.actionItems = actionItems
    }
}

@Model
final class ActionItem {
    var action : String
    var assignedTo : String?
    var priority : Priority
    
    init(action: String, assignedTo: String? = nil, priority: Priority) {
        self.action = action
        self.assignedTo = assignedTo
        self.priority = priority
    }
}
