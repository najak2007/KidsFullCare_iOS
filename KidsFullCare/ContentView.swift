//
//  ContentView.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var authGateViewModel = AuthGateViewModel()
    @State private var userID: String = ""

    init() {
        userID = DeviceIdentifier.shared.getUserID() ?? ""
        
        if !userID.isEmpty {
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { (state, error) in
                switch state {
                case .authorized:
                    print("인증 유효")
                case .revoked, .notFound:
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError as NSError {
                        print("Error signing out: \(signOutError)")
                    }
                default: break
                }
            }
        } else {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError)")
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color("1F2020")
                .ignoresSafeArea()

            if authGateViewModel.state == .checking {
                ProgressView("확인 중....")
            } else {
                if let url = URL(string: Config.KIDS_FULL_CARE_URL) {
                    SignUpView(userViewModel: userViewModel, authGate: authGateViewModel, url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
