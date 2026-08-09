//
//  AuthManager.swift
//  KidsFullCare
//
//  Created by najak on 8/8/26.
//

import SwiftUI
import FirebaseAuth

@Observable
final class AuthManager {
    var user: User?
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        listenToAuthChanges()
    }
    
    private func listenToAuthChanges() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] (result, user) in
#if DEBUG
            print("result = \(result)")
#endif
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
