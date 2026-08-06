//
//  SignUpView.swift
//  KidsFullCare
//
//  Created by najak on 7/26/26.
//

import SwiftUI
import WebKit
import AuthenticationServices
import CryptoKit

struct SignUpView: UIViewRepresentable {
    @ObservedObject var userViewModel: UserViewModel
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // React → Swift 메시지 핸들러 등록
        userContentController.add(context.coordinator, name: "nativeBridge")
        userContentController.add(context.coordinator, name: "appleSignIn")
        // ------------------------------------------------------------------

        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

#if DEBUG
        webView.isInspectable = true
#endif

        webView.scrollView.pinchGestureRecognizer?.delegate = context.coordinator
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.bouncesZoom = false
        webView.allowsLinkPreview = false

        webView.backgroundColor = .white
        userViewModel.webView = webView
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: userViewModel)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, UIGestureRecognizerDelegate {
        let userViewModel: UserViewModel
        var isInitialLoad: Bool = true

        // Apple 로그인 요청 시 사용한 원본(해시 전) nonce.
        // Firebase가 idToken 안의 nonce claim과 비교 검증할 때 필요합니다.
        private var currentNonce: String?

        init(viewModel: UserViewModel) {
            self.userViewModel = viewModel
        }

        func webView(
            _ webView: WKWebView,
            contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
            completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
        ) {
            completionHandler(nil) // nil 리턴 → 메뉴 자체가 뜨지 않음
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
#if DEBUG
            print("userContentController message.name : \(message.name)")
#endif

            if message.name == "nativeBridge" {

            } else if message.name == "appleSignIn" {
                startAppleSignIn()
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }

        // pinch gesture recognizer는 애초에 시작조차 못 하게 차단
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer is UIPinchGestureRecognizer {
                return false
            }
            return true
        }

        private func startAppleSignIn() {
            let nonce = Self.randomNonceString()
            currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce) // 해시된 nonce를 Apple에 전달

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        /// JS로 로그인 성공 결과를 안전하게 전달합니다.
        /// JSONSerialization을 사용해 이름에 특수문자(예: 작은따옴표)가 있어도
        /// JS 문법이 깨지지 않도록 합니다.
        private func sendSuccessCallBack(
            identityToken: String,
            rawNonce: String,
            email: String?,
            name: String?
        ) {
            var payload: [String: Any] = [
                "idToken": identityToken,
                "rawNonce": rawNonce,
            ]
            if let email = email, !email.isEmpty {
                payload["email"] = email
            }
            if let name = name, !name.isEmpty {
                payload["name"] = name
            }

            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else {
#if DEBUG
                print("Apple 로그인 payload 직렬화 실패")
#endif
                sendFailCallBack(errorMessage: "로그인 정보를 처리하는 중 오류가 발생했습니다.")
                return
            }

            let jsScript = "window.onNativeAppleSignIn && window.onNativeAppleSignIn(\(jsonString));"

            DispatchQueue.main.async { [weak self] in
                self?.userViewModel.webView?.evaluateJavaScript(jsScript) { _, error in
                    if let error = error {
#if DEBUG
                        print(error.localizedDescription)
#endif
                    }
                }
            }
        }

        private func sendFailCallBack(errorMessage: String) {
            let payload: [String: Any] = [
                "provider": "apple",
                "message": errorMessage,
            ]

            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return }

            let jsScript = "window.onNativeSignInError && window.onNativeSignInError(\(jsonString));"

            DispatchQueue.main.async { [weak self] in
                self?.userViewModel.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
        }
        
        private func sendCancelCallBack() {
            let jsScript = "window.onNativeSignInError && window.onNativeSignInCancel();"

            DispatchQueue.main.async { [weak self] in
                self?.userViewModel.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
        }
    }
}

extension SignUpView.Coordinator: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    // Apple 로그인 레이어가 떠오를 Window 창 지정 (iOS 15+ 대응)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow()
    }

    // Apple 로그인 인증 성공 시
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            sendFailCallBack(errorMessage: "지원하지 않는 인증 방식입니다.")
            return
        }

        guard let nonce = currentNonce else {
#if DEBUG
            print("currentNonce가 없습니다. startAppleSignIn()이 먼저 호출되었는지 확인하세요.")
#endif
            sendFailCallBack(errorMessage: "로그인 상태가 올바르지 않습니다. 다시 시도해주세요.")
            return
        }

        guard
            let tokenData = appleCredential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            sendFailCallBack(errorMessage: "인증 토큰을 가져오지 못했습니다.")
            return
        }

        // fullName / email은 사용자가 "최초 1회" 로그인할 때만 내려옵니다.
        // 두 번째 로그인부터는 nil이 되므로, 최초 값은 앱(Keychain 등)이나
        // 서버 쪽에서 저장해두고 재사용하는 것을 권장합니다.
        let name = PersonNameComponentsFormatter().string(from: appleCredential.fullName ?? PersonNameComponents())
        let email = appleCredential.email

#if DEBUG
        print("name = \(name), email = \(email ?? ""), tokenString = \(tokenString)")
#endif
        
        sendSuccessCallBack(
            identityToken: tokenString,
            rawNonce: nonce,
            email: email,
            name: name.isEmpty ? nil : name
        )

        currentNonce = nil
    }

    // Apple 로그인 인증 실패/취소 시
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
#if DEBUG
        print("Apple 로그인 실패: \(error.localizedDescription)")
#endif
        currentNonce = nil

        // 사용자가 그냥 취소한 경우는 굳이 에러 메시지를 띄우지 않습니다.
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            sendCancelCallBack()
            return
        }

        sendFailCallBack(errorMessage: error.localizedDescription)
    }
}

// MARK: - Nonce 유틸리티 (Apple 공식 샘플 패턴)

private extension SignUpView.Coordinator {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
#if DEBUG
                    print("SecRandomCopyBytes 실패: \(errorCode)")
#endif
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
