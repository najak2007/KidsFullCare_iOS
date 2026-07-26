//
//  StudentFullCareApp.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI

@main
struct StudentFullCareApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared)
        }
    }
}
