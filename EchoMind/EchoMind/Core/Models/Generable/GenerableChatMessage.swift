//
//  GenerableChatMessage.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/5/25.
//

import Foundation
import FoundationModels

@Generable
struct GenerableChatMessage : Equatable {
    @Guide(description: "This is a chat message that will be used to generate a response to the user's question.")
    let answer : String
}
