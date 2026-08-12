//
//  SignUpView.swift
//  KidsFullCare
//
//  이 WebView는 AuthGateViewModel의 상태를 그대로 JS에 전달만 합니다.
//  Firebase 로그인/Firestore 저장은 전부 AuthGateViewModel(네이티브)이 처리합니다.
//

import SwiftUI
import WebKit
import AuthenticationServices
import CryptoKit
import Combine
import FirebaseAuth

struct SignUpView: UIViewRepresentable {
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var authGate: AuthGateViewModel
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // JS(React) → 네이티브 메시지 핸들러 등록
        userContentController.add(context.coordinator, name: "appleSignIn")
        userContentController.add(context.coordinator, name: "googleSignIn")
        userContentController.add(context.coordinator, name: "roleSelect")   // { role: "parent" | "student" }
        userContentController.add(context.coordinator, name: "signOut")
        userContentController.add(context.coordinator, name: "jsReady")      // JS가 리스너 등록 완료 후 호출
        userContentController.add(context.coordinator, name: "emailSignUp")  // { email, password }
        userContentController.add(context.coordinator, name: "emailSignIn")  // { email, password }

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
        context.coordinator.attach(webView: webView, authGate: authGate)

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
        private weak var webView: WKWebView?
        private var authGate: AuthGateViewModel?
        private var stateCancellable: AnyCancellable?

        // Apple 로그인 요청 시 사용한 원본(해시 전) nonce
        private var currentNonce: String?

        init(viewModel: UserViewModel) {
            self.userViewModel = viewModel
        }

        /// WebView와 AuthGateViewModel을 연결하고, 상태가 바뀔 때마다 JS로 알려줍니다.
        func attach(webView: WKWebView, authGate: AuthGateViewModel) {
            self.webView = webView
            self.authGate = authGate

            stateCancellable = authGate.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.notifyJS(state: state)
                }
        }

        private func notifyJS(state: AuthGateState) {
            var payload: [String: Any] = [:]

            switch state {
            case .checking:
                payload["status"] = "checking"
            case .loggedOut:
                payload["status"] = "loggedOut"
            case .needsRole:
                payload["status"] = "needsRole"
                if let user = try? currentUserSnapshot() {
                    payload["name"] = user.name
                    payload["email"] = user.email
                }
            case .loginCancel:
                payload["status"] = "loginCancel"
            case .loggedIn(let role):
                payload["status"] = "loggedIn"
                payload["role"] = role
            case .signUp:
                payload["status"] = "signUp"
            }

            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return }

            let jsScript = """
                (function() {
                    window.onNativeAuthState && window.onNativeAuthState(\(jsonString));
                    return null;
                })();
                """
            webView?.evaluateJavaScript(jsScript, completionHandler: nil)
        }

        private func currentUserSnapshot() throws -> (name: String, email: String) {
            // FirebaseAuth import 없이 Coordinator를 가볍게 유지하고 싶다면
            // 이 부분은 AuthGateViewModel에 getter를 하나 추가해서 위임해도 됩니다.
            return ("", "")
        }

        func webView(
            _ webView: WKWebView,
            contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
            completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
        ) {
            completionHandler(nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 페이지 로드가 끝나면 현재 상태를 한 번 더 밀어줍니다.
            // (JS의 window.onNativeAuthState 등록이 늦게 끝났을 경우 대비)
            if let authGate {
                notifyJS(state: authGate.state)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
#if DEBUG
            print("bridge message:", message.name, message.body)
#endif
            switch message.name {
            case "appleSignIn":
                startAppleSignIn()
            case "googleSignIn":
                startGoogleSignIn()
            case "roleSelect":
                if let role = message.body as? String {
                    handleRoleSelect(role)
                }
            case "signOut":
                authGate?.signOut()
            case "jsReady":
                // JS가 window.onNativeAuthState 등록을 마쳤다는 신호.
                // 그 시점의 최신 상태를 다시 한번 밀어줘서 타이밍 레이스를 방지합니다.
                if let authGate {
                    notifyJS(state: authGate.state)
                }
            case "emailSignUp":
                if let body = message.body as? [String: Any],
                   let email = body["email"] as? String,
                   let password = body["password"] as? String {
                    handleEmailSignUp(email: email, password: password)
                }
            case "emailSignIn":
                if let body = message.body as? [String: Any],
                   let email = body["email"] as? String,
                   let password = body["password"] as? String {
                    handleEmailSignIn(email: email, password: password)
                }
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer is UIPinchGestureRecognizer {
                return false
            }
            return true
        }

        // MARK: - Apple Sign In

        private func startAppleSignIn() {
            let nonce = Self.randomNonceString()
            currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        // MARK: - Google Sign In (자리만 마련. GoogleSignIn SDK 붙이면 여기서 authGate.signInWithGoogle 호출)

        private func startGoogleSignIn() {
            sendErrorToJS(provider: "google", message: "Google 로그인은 아직 연결되지 않았습니다.", code: nil)
        }

        // MARK: - Role 저장

        private func handleRoleSelect(_ role: String) {
            Task {
                do {
                    try await authGate?.saveRole(role)
                } catch {
                    sendErrorToJS(provider: "role", message: "역할 저장 중 오류가 발생했습니다.", code: nil)
                }
            }
        }

        // MARK: - 이메일/비밀번호 가입 & 로그인

        private func handleEmailSignUp(email: String, password: String) {
            Task {
                do {
                    try await authGate?.signUpWithEmail(email: email, password: password)
                } catch {
                    sendErrorToJS(provider: "email", message: error.localizedDescription, code: Self.firebaseAuthErrorCode(from: error))
                }
            }
        }

        private func handleEmailSignIn(email: String, password: String) {
            Task {
                do {
                    try await authGate?.signInWithEmail(email: email, password: password)
                } catch {
                    sendErrorToJS(provider: "email", message: error.localizedDescription, code: Self.firebaseAuthErrorCode(from: error))
                }
            }
        }

        // MARK: - 에러 전달

        private func sendErrorToJS(provider: String, message: String, code: String?) {
            var payload: [String: Any] = ["provider": provider, "message": message]
            if let code {
                payload["code"] = code
            }
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return }

            let jsScript = """
                (function() {
                    window.onNativeSignInError && window.onNativeSignInError(\(jsonString));
                    return null;
                })();
                """
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
        }
    }
}

extension SignUpView.Coordinator: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            sendErrorToJS(provider: "apple", message: "지원하지 않는 인증 방식입니다.", code: nil)
            return
        }
        guard let nonce = currentNonce else {
            sendErrorToJS(provider: "apple", message: "로그인 상태가 올바르지 않습니다. 다시 시도해주세요.", code: nil)
            return
        }
        guard
            let tokenData = appleCredential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            sendErrorToJS(provider: "apple", message: "인증 토큰을 가져오지 못했습니다.", code: nil)
            return
        }

        currentNonce = nil

        Task {
            do {
                // 핵심: 네이티브가 직접 Firebase에 로그인합니다.
                // 이 한 줄이 성공하면 AuthGateViewModel의 addStateDidChangeListener가
                // 자동으로 반응해서 state가 .needsRole / .loggedIn으로 바뀌고,
                // 그게 다시 JS로 전달됩니다. JS는 아무 Firebase 코드가 필요 없습니다.
                try await authGate?.signInWithApple(identityToken: tokenString, rawNonce: nonce, appleCredential: appleCredential)
            } catch {
                sendErrorToJS(provider: "apple", message: error.localizedDescription, code: Self.firebaseAuthErrorCode(from: error))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        currentNonce = nil
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            notifyJS(state: .loginCancel)
            return // 사용자가 그냥 취소한 경우는 에러 표시 안 함
        }
        sendErrorToJS(provider: "apple", message: error.localizedDescription, code: nil)
    }
}

private extension SignUpView.Coordinator {
    /// Firebase Auth 에러를 JS `convertFirebaseError`에서 쓰는 것과 동일한
    /// "auth/xxx" 문자열 코드로 변환합니다.
    static func firebaseAuthErrorCode(from error: Error) -> String? {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: nsError.code) else {
            return nil
        }
        switch code {
        case .emailAlreadyInUse: return "auth/email-already-in-use"
        case .invalidEmail: return "auth/invalid-email"
        case .weakPassword: return "auth/weak-password"
        case .wrongPassword: return "auth/wrong-password"
        case .userNotFound: return "auth/user-not-found"
        case .userDisabled: return "auth/user-disabled"
        case .invalidCredential: return "auth/invalid-credential"
        case .accountExistsWithDifferentCredential: return "auth/account-exists-with-different-credential"
        default: return nil
        }
    }
}

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
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
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
