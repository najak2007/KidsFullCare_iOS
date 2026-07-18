//
//  GetSchoolScheduleIntent.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import AppIntents

//struct GetSchoolScheduleIntent: AppIntent {
//    static var title: LocalizedStringResource = "학교 일정 조회"
//    
//    @Parameter(title: "날짜", default: .today)
//    var date: Date
//    
//    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
//        let scheduleInfo = await SchoolAPIManager.fetchSchedult(for: date)
//        
//        let speechText: IntentDialog = scheduleInfo.isEmpty
//            ? "해당 날짜에는 등록된 수업이나 일정이 없습니다."
//            : "요청하신 날짜의 수업은 \(scheduleInfo) 입니다."
//        
//        let snippetView = SchoolScheduleSnippetView(date: date, schedules: scheduleInfo)
//        
//        return .result(dialog: speechText, view: snippetView)
//    }
//}
