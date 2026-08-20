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
    @StateObject private var faceIDManager = FaceIDManager()
    @State private var webViewFirstLoadDone = false
    @State private var showAlert = false
    @State private var password: String? = ""
    
    init() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
#if DEBUG
            print("Error signing out: \(signOutError)")
#endif
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

#if true
            if authGateViewModel.state == .checking {
                ProgressView("확인 중....")
                    .background(Color(.systemBackground))
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
#else
            if authGateViewModel.state == .checking {
                ProgressView("확인 중....")
                    .background(Color(.systemBackground))
            } else if authGateViewModel.state == .loggedIn(role: "parent") || authGateViewModel.state == .loggedIn(role: "student") {
                
                MainView(userViewModel: userViewModel, authGate: authGateViewModel)
                
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
#endif
            
            if(!webViewFirstLoadDone) {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.25), value: webViewFirstLoadDone)
        .onReceive(bioAuthRequest) { password in
            if authGateViewModel.isUseBiometricAck == .사용여부_질문필요 {
                self.password = password
                showAlert.toggle()
            }
            
        }
        .alert("로그인 방법", isPresented: $showAlert) {
            Button("사용", role: .none) {
                DispatchQueue.main.async {
                    faceIDManager.authenticate(self.password ?? "") { isResult, _ in
                        if isResult {
                            authGateViewModel.isUseBiometricAck = .사용
                            return
                        }
                        authGateViewModel.isUseBiometricAck = .사용하지_않음
                        self.password = nil
                    }
                }
            }
            Button("취소", role: .cancel) {
                authGateViewModel.isUseBiometricAck = .사용하지_않음
                self.password = nil
            }
        } message: {
            Text("생체 인증을 통해 로그인하시겠습니까?")
        }
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
