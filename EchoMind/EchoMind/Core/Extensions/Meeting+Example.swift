//
//  Meeting+Example.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/6/25.
//

import Foundation

extension Meeting {
    static func createExampleMeetings() -> [Meeting] {
        // Create sample action items
        let actionItems1 = [
            ActionItem(
                action: "Purchase laptop computer with Data Processing Reserve funds",
                assignedTo: "County Clerk's office",
                priority: .medium
            ),
            ActionItem(
                action: "Correct minutes to include Commissioner McCroskey on Special Committee",
                assignedTo: "Clerk",
                priority: .low
            ),
            ActionItem(
                action: "Budget Committee meeting on solid waste funding recommendations",
                assignedTo: "Budget Committee members",
                priority: .high
            ),
            ActionItem(
                action: "Second reading preparation for wheel tax increase resolution",
                assignedTo: "Commission",
                priority: .high
            )
        ]
        
        let actionItems2 = [
            ActionItem(
                action: "Review Q4 sales performance metrics",
                assignedTo: "Sarah Johnson",
                priority: .high
            ),
            ActionItem(
                action: "Prepare marketing campaign proposal for new product launch",
                assignedTo: "Marketing Team",
                priority: .medium
            ),
            ActionItem(
                action: "Schedule follow-up meeting with stakeholders",
                assignedTo: "Project Manager",
                priority: .low
            )
        ]
        
        let actionItems3 = [
            ActionItem(
                action: "Update project timeline for mobile app release",
                assignedTo: "Development Team",
                priority: .high
            ),
            ActionItem(
                action: "Conduct user testing for new features",
                assignedTo: "UX Team",
                priority: .medium
            )
        ]
        
        // Create sample meeting summaries
        let summary1 = MeetingSummary(
            title: "CTAS County Commission Budget and Tax Meeting",
            transcript: "The CTAS County Commission convened to address several budget and tax matters. Key agenda items included approving equipment purchases, discussing property sales, and voting on tax increases. The commission approved a resolution to purchase a laptop computer for the County Clerk's office using reserve funds. Commissioner McKee withdrew his motion to sell airport property. The major discussion centered on increasing litigation taxes, with an amendment requiring 25% of criminal case proceeds to fund the sheriff's department. However, this motion failed in a tied 9-9 vote. The commission then considered a $10 wheel tax increase to offset state education funding cuts. After extensive debate, previous question was called to end discussion, and the wheel tax increase passed 17-2 on first reading. The meeting concluded with committee announcements and scheduling of future meetings.",
            actionItems: actionItems1
        )
        
        let summary2 = MeetingSummary(
            title: "Q4 Sales Review and Planning Meeting",
            transcript: "The sales team gathered to review Q4 performance and plan for the upcoming quarter. Key discussions included revenue targets, new product launches, and customer feedback analysis. The team exceeded their Q4 goals by 15%, with particularly strong performance in the enterprise segment. Marketing presented their proposal for the new product campaign, which received positive feedback from the leadership team. Customer satisfaction scores remain high at 4.8/5. The team identified opportunities for improvement in lead conversion rates and plans to implement new CRM features. Next quarter's targets were set with a focus on sustainable growth and customer retention.",
            actionItems: actionItems2
        )
        
        // Create sample meetings
        let meeting1 = Meeting(
            id: UUID(),
            title: "County Commission Budget Meeting",
            timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            rawTranscript: try? AttributedString(markdown: "**County Commission Meeting Transcript**\n\nThe CTAS County Commission convened to address several budget and tax matters..."),
            summary: summary1,
            url: nil,
            isDone: true
        )
        
        let meeting2 = Meeting(
            id: UUID(),
            title: "Q4 Sales Review and Planning",
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            rawTranscript: try? AttributedString(markdown: "**Sales Team Meeting Transcript**\n\nThe sales team gathered to review Q4 performance..."),
            summary: summary2,
            url: nil,
            isDone: true
        )
        
        let meeting3 = Meeting(
            id: UUID(),
            title: "Mobile App Development Sprint Review",
            timestamp: Date(),
            rawTranscript: try? AttributedString(markdown: "**Sprint Review Transcript**\n\nDevelopment team presented the latest features for the mobile app..."),
            summary: MeetingSummary(
                title: "Mobile App Development Sprint Review",
                transcript: "Development team presented the latest features for the mobile app. Key accomplishments include completion of user authentication, implementation of push notifications, and improved app performance. The team identified several bugs that need addressing before the next release. UX feedback highlighted the need for better onboarding flow. The sprint was largely successful with 8 out of 10 planned features completed. Next sprint will focus on bug fixes and user experience improvements.",
                actionItems: actionItems3
            ),
            url: nil,
            isDone: false
        )
        
        let meeting4 = Meeting(
            id: UUID(),
            title: "Weekly Team Standup",
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            rawTranscript: try? AttributedString(markdown: "**Team Standup Transcript**\n\nTeam members shared updates on their current tasks..."),
            summary: nil,
            url: nil,
            isDone: false
        )
        
        let meeting5 = Meeting(
            id: UUID(),
            title: "Product Strategy Discussion",
            timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            rawTranscript: nil,
            summary: nil,
            url: nil,
            isDone: false
        )
        
        return [meeting1, meeting2, meeting3, meeting4, meeting5]
    }
}