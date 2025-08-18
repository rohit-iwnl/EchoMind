//
//  ChatMessage.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/5/25.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var messageID : UUID
    @Attribute(.externalStorage) var content: String
    var timestamp : Date
    var isUserMessage : Bool
    @Relationship(inverse: \Meeting.chatMessages) var meeting: Meeting?
    
    init(messageID : UUID, content: String, timestamp: Date, isUserMessage: Bool = true, meeting: Meeting? = nil) {
        self.messageID = messageID
        self.content = content
        self.timestamp = timestamp
        self.isUserMessage = isUserMessage
        self.meeting = meeting
    }
}
