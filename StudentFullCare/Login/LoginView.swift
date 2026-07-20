//
//  LoginView.swift
//  StudentFullCare
//
//  Created by najak on 7/20/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var loginMessage = "로그인이 필요합니다."
    
    var body: some View {
        VStack(spacing: 20) {
            Text(loginMessage)
                .font(.headline)
                .padding()
            
            // 1. SwiftUI 전용 Sign In with Apple 버튼 배경
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleSignInResult(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(width: 280, height: 45)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(var authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                if let identityToken = appleIDCredential.identityToken,
                   let tokenString = String(data: identityToken, encoding: .utf8) {
                    print("Identity Token: \(tokenString)")
                    // TODO: 이 토큰을 자체 백앤드 서버로 보내 위변조 검증을 수행해야 안전합니다.
                }
                print("User ID: \(userIdentifier)")
                print("Email: \(email ?? "알수 없음")")
                if let name = fullName {
                    print("Name: \(name.givenName ?? "") \(name.familyName ?? "")")
                }
                
                withAnimation {
                    loginMessage = "로그인 성고! 사용자 ID : \(userIdentifier.prefix(8))..."
                }
            }
        case .failure(let error):
            print("Apple 로그인 실패: \(error.localizedDescription)")
            withAnimation {
                loginMessage = "로그인에 실패했습니다."
            }
        }
    }
}
