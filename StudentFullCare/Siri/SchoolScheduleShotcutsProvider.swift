//
//  SchoolScheduleShotcutsProvider.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import AppIntents

struct SchoolScheduleShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetSchoolScheduleIntent(),
            phrases: [
                "\(.applicationName)에서 오늘 수업 알려줘",
                "\(.applicationName) 일정 확인해줘",
                "\(.applicationName) 수업 뭐 있어"
            ],
            shortTitle: "학교 일정 확인",
            systemImageName: "calendar"
        )
    }
}
