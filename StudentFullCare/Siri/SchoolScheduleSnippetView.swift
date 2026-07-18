//
//  SchoolScheduleSnippetView.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import Foundation

struct SchoolScheduleSnippetView: View {
    let date: Date
    let schedules: [ScheduleInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
            
            Divider()
            
            if schedules.isEmpty {
                Text("일정이 없습니다.")
                    .font(.body)
            } else {
                ForEach(schedules, id: \.self) { item in
                    HStack {
                        Image(systemName: "book.pages")
                            .foregroundColor(.blue)
                        
                        Text(item)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
    }
}
