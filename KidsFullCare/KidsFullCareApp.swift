//
//  KidsFullCareApp.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import FirebaseAuth

@main
struct KidsFullCareApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared)
        }
    }
}
