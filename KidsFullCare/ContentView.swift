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
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var authGateViewModel = AuthGateViewModel()
    

    init() {
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
              let user = userInfo["user"] as? String
        else {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
#if DEBUG
                print("Error signing out: \(signOutError)")
#endif
            }
            return
        }
        if !user.isEmpty {
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: user) { (state, error) in
                switch state {
                case .authorized:
                    print("인증 유효")
                case .revoked, .notFound:
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError as NSError {
#if DEBUG
                        print("Error signing out: \(signOutError)")
#endif
                    }
                default: break
                }
            }
        } else {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
#if DEBUG
                print("Error signing out: \(signOutError)")
#endif
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
