//
//  KidsFullCareApp.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import FirebaseAuth
import Firebase

@main
struct KidsFullCareApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    
    init() {
        FirebaseApp.configure()
        _authManager = State(wrappedValue: AuthManager())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}
