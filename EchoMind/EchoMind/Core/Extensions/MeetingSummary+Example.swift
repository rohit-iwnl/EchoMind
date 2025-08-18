//
//  MeetingSummary+Example.swift
//  EchoMind
//
//  Created by Rohit Manivel on 8/4/25.
//

import Foundation

extension GenerableMeetingDetails {
    static let exampleMeeting = GenerableMeetingDetails(
        smartTitle: "CTAS County Commission Budget and Tax Meeting",

        smartTranscript:
            "The CTAS County Commission convened to address several budget and tax matters. Key agenda items included approving equipment purchases, discussing property sales, and voting on tax increases. The commission approved a resolution to purchase a laptop computer for the County Clerk's office using reserve funds. Commissioner McKee withdrew his motion to sell airport property. The major discussion centered on increasing litigation taxes, with an amendment requiring 25% of criminal case proceeds to fund the sheriff's department. However, this motion failed in a tied 9-9 vote. The commission then considered a $10 wheel tax increase to offset state education funding cuts. After extensive debate, previous question was called to end discussion, and the wheel tax increase passed 17-2 on first reading. The meeting concluded with committee announcements and scheduling of future meetings.",

        actionItems: [
            GenerableActionItems(
                actionItemTitle:
                    "Purchase laptop computer with Data Processing Reserve funds",
                assignedTo: "County Clerk's office",
                priority: .medium
            ),
            GenerableActionItems(
                actionItemTitle:
                    "Correct minutes to include Commissioner McCroskey on Special Committee",
                assignedTo: "Clerk",
                priority: .low
            ),
            GenerableActionItems(
                actionItemTitle:
                    "Budget Committee meeting on solid waste funding recommendations",
                assignedTo: "Budget Committee members",
                priority: .high
            ),
            GenerableActionItems(
                actionItemTitle:
                    "Second reading preparation for wheel tax increase resolution",
                assignedTo: "Commission",
                priority: .high
            ),
        ]
    )

}
