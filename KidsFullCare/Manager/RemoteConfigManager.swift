//
//  RemoteConfigManager.swift
//  KidsFullCare
//
//  Created by najak on 9/28/26.
//

import FirebaseRemoteConfig
import SwiftUI
import Combine

@MainActor
final class RemoteConfigManager: ObservableObject {
    @Published var menus: [StudentMenu] = []

    private let remoteConfig = RemoteConfig.remoteConfig()
    private let configKey = "student_menus"

    private let defaultMenusJson = """
    [
      {"key":"school","label":"학교 등록","icon":"🏫","color":"#4C8DFF"},
      {"key":"academy","label":"학원 등록","icon":"📚","color":"#FF9F40"},
      {"key":"class","label":"수업 등록","icon":"📝","color":"#34C77B"},
      {"key":"timetable","label":"시간표","icon":"🗓️","color":"#A566FF"},
      {"key":"notice","label":"알림장","icon":"📢","color":"#FF5A6E"},
      {"key":"parentLink","label":"부모님 연결","icon":"🔗","color":"#20C4C8"}
    ]
    """
    
    var menuInfoHandler: (([StudentMenu]) -> Void)? = nil
    
    
    init() {}

    func start(completion: @escaping([StudentMenu]) -> Void) {
        let settings = RemoteConfigSettings()
#if DEBUG
        settings.minimumFetchInterval = 0
#else
        settings.minimumFetchInterval = 86400
#endif
        menuInfoHandler = completion
        
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([configKey: defaultMenusJson as NSString])

        applyCurrentValue()   // 기본값/캐시로 먼저 채움
        fetchRemoteValues()
    }
    
    func fetchRemoteValues() {
        Task {
            do {
                _ = try await remoteConfig.fetchAndActivate()
            } catch {
#if DEBUG
                print("RemoteConfig fetch 실패: \(error)")
#endif
            }
            applyCurrentValue()   // 성공/실패 모두 현재 값(캐시 또는 기본값)으로 갱신
        }
    }

    private func applyCurrentValue() {
        let menuJsonString = remoteConfig[configKey].stringValue
        if !menuJsonString.isEmpty, let jsonData = menuJsonString.data(using: .utf8) {
            do {
                let menuItems = try JSONDecoder().decode([StudentMenu].self, from: jsonData)
                if !menuItems.isEmpty {
                    menus = menuItems
                    menuInfoHandler?(menuItems)
                }
                return
            } catch {
                
            }
        }
        do {
            if let jsonData = defaultMenusJson.data(using: .utf8) {
                let menuItems = try JSONDecoder().decode([StudentMenu].self, from: jsonData)
                if !menuItems.isEmpty {
                    menus = menuItems
                    menuInfoHandler?(menuItems)
                }
            }
        } catch {
            
        }
    }

    private func decode(_ json: String) -> [StudentMenu]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([StudentMenu].self, from: data)
    }
}
