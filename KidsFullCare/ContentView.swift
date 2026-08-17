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
    @State private var webViewFirstLoadDone = false
    
    init() {
#if true
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
#if DEBUG
            print("Error signing out: \(signOutError)")
#endif
        }
#else
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
#endif
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if authGateViewModel.state == .checking {
                ProgressView("확인 중....")
                    .background(Color(.systemBackground))
            } else if authGateViewModel.state == .loggedIn(role: "parent" ) {
                MainView(userViewModel: userViewModel, authGate: authGateViewModel)
            } else if authGateViewModel.state == .loggedIn(role: "student" ) {
                
            } else {
                if let url = URL(string: Config.KIDS_FULL_CARE_URL) {
                    SignUpView(userViewModel: userViewModel, authGate: authGateViewModel, url: url, onFirstLoad: {
                        webViewFirstLoadDone = true
                    })
                        .ignoresSafeArea() // 안전 영역 무시하고 꽉 채우기
                        .onOpenURL { url in
                            handleIncomingLink(url)
                        }
                }
            }
            
            if(!webViewFirstLoadDone) {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.25), value: webViewFirstLoadDone)
    }
    
    /// https://kidsfullcare.app/link?code=123456&uid=xxx 형태의 유니버설 링크를 받아서
    /// code/uid를 뽑아 JS로 전달합니다. (QR을 카메라로 찍었을 때 이 경로로 앱이 열립니다)
    private func handleIncomingLink(_ url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.path == "/link",
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
            let uid = components.queryItems?.first(where: { $0.name == "uid" })?.value
        else {
            return
        }
 
        userViewModel.webView?.notifyIncomingLinkCode(code: code, uid: uid)
    }
}
