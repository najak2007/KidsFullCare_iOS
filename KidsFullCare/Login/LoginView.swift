//
//  LoginView.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import SwiftUI
import AuthenticationServices
import FirebaseFirestore
import FirebaseRemoteConfig
import FirebaseAuth

struct LoginView: View {
    @State private var loginMessage = "로그인이 필요합니다."
    @State private var isLoginReq: Bool = false
    
    @State private var fullName: PersonNameComponents? = nil
    @State private var email: String? = nil
    @State private var userIdentifier: String? = nil
    @State private var loginToken: String = ""
    @State private var signInManager = AppleSignInManager()
    
    init() {
        guard let _ = Auth.auth().currentUser?.uid else {
            loginMessage = "이미 로그인되어 있습니다."
            return
        }
        isLoginReq = true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoginReq == false {
                Text(loginMessage)
                .font(.headline)
                .padding()
            } else {
                Text(loginMessage)
                .font(.headline)
                .padding()
                
                // 1. SwiftUI 전용 Sign In with Apple 버튼 배경
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        let nonce = signInManager.randomNonceString()
                        signInManager.currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = signInManager.sha256(nonce)
                    },
                    onCompletion: { result in
                        handleSignInResult(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 280, height: 45)
                .cornerRadius(8)
                }
        }
        .padding()
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
#if true
            signInManager.handleAuthorization(authorization)
#else
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userIdentifier = appleIDCredential.user
                fullName = appleIDCredential.fullName
                email = appleIDCredential.email
                
                if let identityToken = appleIDCredential.identityToken,
                   let tokenString = String(data: identityToken, encoding: .utf8) {
                    print("Identity Token: \(tokenString)")
                    // TODO: 이 토큰을 자체 백앤드 서버로 보내 위변조 검증을 수행해야 안전합니다.
                    loginToken = tokenString
                    login()
                }
                print("User ID: \(userIdentifier)")
                print("Email: \(email ?? "알수 없음")")
                if let name = fullName {
                    print("Name: \(name.givenName ?? "") \(name.familyName ?? "")")
                }

            }
#endif
        case .failure(let error):
            print("Apple 로그인 실패: \(error.localizedDescription)")
            withAnimation {
                loginMessage = "로그인에 실패했습니다."
            }
        }
    }
}
