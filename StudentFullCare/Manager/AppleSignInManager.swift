//
//  AppleSignInManager.swift
//  StudentFullCare
//
//  Created by 오션블루 on 7/21/26.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

@Observable
class AppleSignInManager: NSObject {
    var currentNonce: String?

    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // 공통 처리 메서드로 분리
    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("ASAuthorizationAppleIDCredential 캐스팅 실패")
            return
        }
        guard let nonce = currentNonce else {
            fatalError("Invalid state: nonce가 없습니다. 로그인 요청이 시작되지 않았을 수 있습니다.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("identityToken을 가져올 수 없습니다.")
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("identityToken을 문자열로 변환할 수 없습니다.")
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase 로그인 실패: \(error.localizedDescription)")
                return
            }
            print("로그인 성공: \(authResult?.user.uid ?? "")")
            // TODO: LHHouseNoti 유저 문서 생성/업데이트, App Group UserDefaults 갱신 등
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAuthorization(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple 로그인 실패: \(error.localizedDescription)")
    }
}


extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // UIWindowScene에서 window 반환
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}
