//
//  Meeting.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/3/25.
//

import Foundation
import SwiftData

@Model
final class Meeting {
    @Attribute(.unique) var id : UUID
    var title : String
    var timestamp : Date
    
    var url : URL?
    
    var isDone : Bool
    
    @Attribute(.externalStorage) var notes : [String?]?
    
    @Attribute(.externalStorage) var rawTranscript : AttributedString?
    
    @Relationship(deleteRule: .cascade) var summary : MeetingSummary?
    @Relationship(deleteRule: .cascade) var chatMessages: [ChatMessage] = []
    
    
    init(id: UUID, title: String, timestamp: Date, notes : [String?]? = nil, rawTranscript: AttributedString? = nil, summary: MeetingSummary? = nil, url: URL? = nil, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.notes = notes
        self.rawTranscript = rawTranscript
        self.summary = summary
        self.url = url
        self.isDone = isDone
    }
}
