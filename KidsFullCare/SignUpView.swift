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
import PhotosUI
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}


struct SignUpView: UIViewRepresentable {
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var authGate: AuthGateViewModel
    
    let url: URL
    var onFirstLoad: (() -> Void)?

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
        userContentController.add(context.coordinator, name: "generateLinkCode")
        userContentController.add(context.coordinator, name: "resetDevice")
        userContentController.add(context.coordinator, name: "inputFocus")
        userContentController.add(context.coordinator, name: "pickProfileImage")
        userContentController.add(context.coordinator, name: "addFamilyForUID")
        userContentController.add(context.coordinator, name: "qrCodeAuthTimeLimit")
        userContentController.add(context.coordinator, name: "fetchProfileImage")
        userContentController.add(context.coordinator, name: "addFamilyReq")

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
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        webView.isOpaque = true
        webView.underPageBackgroundColor = .systemBackground

        userViewModel.webView = webView
        context.coordinator.attach(webView: webView, authGate: authGate, onFirstLoad: onFirstLoad)

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
        private weak var webView: WKWebView?
        private var authGate: AuthGateViewModel?
        private var stateCancellable: AnyCancellable?
        private var onFirstLoad: (() -> Void)?

        // Apple 로그인 요청 시 사용한 원본(해시 전) nonce
        private var currentNonce: String?

        init(viewModel: UserViewModel) {
            self.userViewModel = viewModel
        }

        /// WebView와 AuthGateViewModel을 연결하고, 상태가 바뀔 때마다 JS로 알려줍니다.
        func attach(webView: WKWebView, authGate: AuthGateViewModel, onFirstLoad: (() -> Void)?) {
            self.webView = webView
            self.authGate = authGate
            self.onFirstLoad = onFirstLoad

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
            case .loggedOut(let returningUser, let provider):
                payload["status"] = "loggedOut"
                payload["returningUser"] = returningUser
                payload["provider"] = provider
            case .needsRole(let name):
                payload["status"] = "needsRole"
                payload["name"] = name
            case .loginCancel:
                payload["status"] = "loginCancel"
            case .loggedIn(let role, let profileImg):
                payload["status"] = "loggedIn"
                payload["role"] = role
                payload["name"] = DeviceIdentifier.shared.getUserForKey("displayName")
                payload["imageBase64"] = profileImg
                payload["familyMembers"] = authGate?.familyMembers
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
            
            if isInitialLoad {
                isInitialLoad = false
                onFirstLoad?()
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
                if let body = message.body as? [String: Any], let role = body["role"] as? String {
                    handleRoleSelect(role: role, extra: body)
                } else if let role = message.body as? String {
                    // 이전 방식(문자열만 전달) 호환용
                    handleRoleSelect(role: role, extra: [:])
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
                   let name = body["name"] as? String,
                   let email = body["email"] as? String,
                   let password = body["password"] as? String {
                    handleEmailSignUp(name: name, email: email, password: password)
                }
            case "emailSignIn":
                if let body = message.body as? [String: Any],
                   let email = body["email"] as? String,
                   let password = body["password"] as? String {
                    handleEmailSignIn(email: email, password: password)
                }
            case "generateLinkCode":
                handleGenerateLinkCode()
            case "resetDevice":
                Task {
                    try await authGate?.resetDevice()
                }
            case "inputFocus":
                if let fieldName = message.body as? String {
                    handleInputFocus(fieldName: fieldName)
                }
            case "pickProfileImage":
                handlePickProfileImage()
            case "addFamilyForUID":
                if let body = message.body as? [String: Any],
                   let addUid = body["uid"] as? String,
                   let addName = body["name"] as? String {
                    handleAddFamily(uid: addUid, name: addName)
                }
            case "qrCodeAuthTimeLimit":
                if let authCode = message.body as? String {
                    handleQRCodeAuthTimeLimit(code: authCode)
                }
            case "fetchProfileImage":
                if let uid = message.body as? String {
                    Task {
                        let imageBase64 = try? await self.authGate?.fetchProfile(fetchUid: uid)
                        self.sendProfileImageResult(uid: uid, imageBase64: imageBase64)
                    }
                }
            case "addFamilyReq":
                if let role = message.body as? String {
                    handleAddFamilyRequest(role: role)
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
        
        private func resetDeviceForAuth() {
            if let provider = DeviceIdentifier.shared.getUserForKey("provider") {
                if provider == "apple" {
                    
                } else if provider == "google" {
                    
                } else if provider == "email" {
                    
                }
            }
        }

        // MARK: - Google Sign In (자리만 마련. GoogleSignIn SDK 붙이면 여기서 authGate.signInWithGoogle 호출)

        private func startGoogleSignIn() {
            sendErrorToJS(provider: "google", message: "Google 로그인은 아직 연결되지 않았습니다.", code: nil)
        }

        // MARK: - Role 저장

        private func handleRoleSelect(role: String, extra: [String: Any]) {
            Task {
                do {
                    try await authGate?.saveRole(role, extra: extra)
                } catch {
                    sendErrorToJS(provider: "role", message: "역할 저장 중 오류가 발생했습니다.", code: nil)
                }
            }
        }

        // MARK: - 이메일/비밀번호 가입 & 로그인

        private func handleEmailSignUp(name: String, email: String, password: String) {
            Task {
                do {
                    try await authGate?.signUpWithEmail(name: name, email: email, password: password)
                    self.scrollWebViewToTop()
                } catch {
                    sendErrorToJS(provider: "email", message: error.localizedDescription, code: Self.firebaseAuthErrorCode(from: error))
                }
            }
        }

        private func handleQRCodeAuthTimeLimit(code: String) {
            guard let uid = Auth.auth().currentUser?.uid

            else {
                return
            }
            
            LinkCodeListener.shared.startListening(codeId: code, studentUid: uid) { parents in
                guard let parents = parents,
                      let parentInfo = parents.first,
                      let parentUid = parentInfo["uid"] as? String,
                      let parentName = parentInfo["name"] as? String
                else {
                    return
                }
                
                self.authGate?.addFamily(familyUid: parentUid , familyName: parentName) { isResult in
                    self.sendQRCodeAuthResultHandler(isResult: isResult, codeId: code, familyUid: parentUid, familyName: parentName)
                }
            }
        }
        
        private func sendProfileImageResult(uid: String, imageBase64: String?) {
            var payload: [String: Any] = ["uid": uid]
            
            if let imageBase64, !imageBase64.isEmpty {
                payload["imageBase64"] = imageBase64
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
            
            let jsScript = """
                (function() {
                    window.onNativeFamilyProfileImage && window.onNativeFamilyProfileImage(\(jsonString));
                    return null;
                })();
                """
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
        }
        
        private func sendQRCodeAuthResultHandler(isResult: AddFamilyState, codeId: String, familyUid: String, familyName: String) {
            let payload: [String: Any] = [
                "name": familyName,
                "result": "\(isResult.K)",
                "code": codeId
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
            let jsScript = """
                (function() {
                    window.onNativeQRCodeAuthComplete && window.onNativeQRCodeAuthComplete(\(jsonString));
                    return null;
                })();
                """
            
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
            return
        }
        
        private func handleEmailSignIn(email: String, password: String) {
            Task {
                do {
                    try await authGate?.signInWithEmail(email: email, password: password)
                    self.scrollWebViewToTop()
                } catch {
                    sendErrorToJS(provider: "email", message: error.localizedDescription, code: Self.firebaseAuthErrorCode(from: error))
                }
            }
        }

        /// 로그인/화면 전환 직후 웹뷰 콘텐츠를 맨 위로 스크롤합니다.
        private func scrollWebViewToTop() {
            DispatchQueue.main.async { [weak self] in
                guard let scrollView = self?.webView?.scrollView
                else {
                    return
                }
                let target = CGPoint(
                    x: -scrollView.adjustedContentInset.left,
                    y: -scrollView.adjustedContentInset.top
                )
                scrollView.setContentOffset(target, animated: true)
            }
        }
        
        private func handleInputFocus(fieldName: String) {
#if DEBUG
            print("handleInputFocus fieldName = \(fieldName)")
#endif
            if self.authGate?.isUseBiometricAck == .사용 {
                FaceIDManager().authenticate(completion: { [weak self] (isResult, keyID) in
                    if isResult, let faceID = keyID {
                        if let email = DeviceIdentifier.shared.getUserForKey("email"),
                           let password = DeviceIdentifier.shared.getUserPassword(faceID) {
                            self?.sendBiometricLoginResult(email: email, password: password)
                        }
                    }
                })
            }
        }
        
        private func sendBiometricLoginResult(email: String, password: String) {
            Task {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
            
            let payload: [String: Any] = [
                "email": email,
                "password": password
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
            
            let jsScript = """
                (function() {
                    window.onNativeBiometricLogin && window.onNativeBiometricLogin(\(jsonString));
                    return null;
                })();
                """
            
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
            }
        }
        
        private func handleAddFamily(uid: String, name: String) {
#if DEBUG
            print("handleAddFamily uid: \(uid), name: \(name)")
#endif
            
            self.authGate?.addFamily(familyUid: uid, familyName: name) { isResult in
                let payload: [String: Any] = [
                    "addUserName": name,
                    "addUserUid": uid,
                    "linkResult": "\(isResult.K)"
                ]
                
#if DEBUG
                print("handleAddFamily: \(payload)")
#endif
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                      let jsonString = String(data: jsonData, encoding: .utf8)
                else {
                    return
                }
                
                let jsScript = """
                    (function() {
                        window.onNativeAddFamilyForName && window.onNativeAddFamilyForName(\(jsonString));
                        return null;
                    })();
                    """
                
                DispatchQueue.main.async { [weak self] in
                    self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
                }
            }
        }
        
        private func handleAddFamilyRequest(role: String) {
            if role == "parent" {
                DispatchQueue.main.async { [weak self] in
                    guard let self, let rootVC = self.topViewController()
                    else {
                        return
                    }
                    presentQRScanner(from: rootVC)
                }
            } else {
                let jsScript = """
                    (function() {
                        window.onNativeLinkQRCodeShow && window.onNativeLinkQRCodeShow();
                        return null;
                    })();
                    """
                DispatchQueue.main.async { [weak self] in
                    self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
                }
            }
        }
        
        private func handlePickProfileImage() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let rootVC = self.topViewController()
                else {
                    return
                }
                
                let alert = UIAlertController(title: "프로필 사진", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "카메라로 촬영", style: .default) { [weak self] _ in
                    self?.presentCamera(from: rootVC)
                })
                
                alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
                    self?.presentPhotoPicker(from: rootVC)
                })
                
                alert.addAction(UIAlertAction(title: "이미지 삭제", style: .default) { [weak self] _ in
                    self?.sendPickedImage(nil)
                })
                                
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootVC.present(alert, animated: true)
            }
        }
        
        private func topViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else {
                return nil
            }
            
            var top = rootVC
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
        
        private func presentQRScanner(from viewController: UIViewController) {
            let scannerVC = QRScannerViewController()
            scannerVC.onCodeScanned = { [weak self] studentInfo in
                if let studentInfo = studentInfo {
                    Task {
                        if let uid = Auth.auth().currentUser?.uid {
                            if let matchUid: (Bool, String) = try await self?.authGate?.fetchStudentForCodeWithUid(code: studentInfo.code, uid: studentInfo.uid, parentUid: uid, parentName: studentInfo.name ?? DeviceIdentifier.shared.getUserForKey("displayName") ?? "") {
                                if matchUid.0 {
                                    self?.webView?.notifyIncomingLinkCode(uid: studentInfo.uid, name: studentInfo.name ?? "")
                                } 
                            }
                        }
                    }
                }
            }
            scannerVC.modalPresentationStyle = .fullScreen
            viewController.present(scannerVC, animated: true)
        }
        
        private func presentCamera(from viewController: UIViewController) {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                sendErrorToJS(provider: "profileImage", message: "카메라를 사용할 수 없습니다.", code: nil)
                return
            }
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            
            viewController.present(picker, animated: true)
        }
 
        private func presentPhotoPicker(from viewController: UIViewController) {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            viewController.present(picker, animated: true)
        }
 
        private func sendPickedImage(_ profileImage: UIImage?) {
            guard let image = profileImage else {
                let payload: [String: Any] = [
                    "imageBase64": ""
                ]

                guard
                    let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                    let jsonString = String(data: jsonData, encoding: .utf8)
                else { return }
     
                let jsScript = """
                    (function() {
                        window.onNativeProfileImagePicked && window.onNativeProfileImagePicked(\(jsonString));
                        return null;
                    })();
                    """
                webView?.evaluateJavaScript(jsScript, completionHandler: { [weak self] _ ,_  in
                    if let uid = Auth.auth().currentUser?.uid {
                        Task {
                            try await self?.authGate?.saveProfileImage(uid: uid, imageBase64: "")
                        }
                    }
                })
                return
            }
            
            // 원본 용량이 클 수 있으니 리사이즈 + JPEG 압축 후 base64로 인코딩합니다.
            guard
                let resized = image.resizedForUpload(maxDimension: 120),
                let jpegData = resized.jpegData(compressionQuality: 0.7)
            else {
                sendErrorToJS(provider: "profileImage", message: "이미지를 처리하지 못했습니다.", code: nil)
                return
            }

            let profileImageBase64 = jpegData.base64EncodedString()
            
            if let uid = Auth.auth().currentUser?.uid {
                Task {
                    try await self.authGate?.saveProfileImage(uid: uid, imageBase64: profileImageBase64)
                }
                let payload: [String: Any] = ["imageBase64": profileImageBase64]
                guard
                    let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                    let jsonString = String(data: jsonData, encoding: .utf8)
                else { return }
                
                let jsScript = """
                (function() {
                    window.onNativeProfileImagePicked && window.onNativeProfileImagePicked(\(jsonString));
                    return null;
                })();
                """
                webView?.evaluateJavaScript(jsScript, completionHandler: {  _, _ in
                })
            }
        }
        
        private func handleGenerateLinkCode() {
            Task {
                do {
                    if let generateLinkCodeResult = try await authGate?.generateStudentLinkCode() {
                        sendLinkCodeResult(code: generateLinkCodeResult.code, uid: generateLinkCodeResult.uid, name: generateLinkCodeResult.name, errorMessage: nil)
                    } else {
                        sendLinkCodeResult(code: nil, uid: nil, name: nil, errorMessage: "코드 생성 중 오류가 발생했습니다.")
                    }
                } catch {
                    sendLinkCodeResult(code: nil, uid: nil, name: nil, errorMessage: "코드 생성 중 오류가 발생했습니다.")
                }
            }
        }
        
        /// roleSelect/emailSignIn 등과 콜백 이름이 겹치지 않도록 전용 콜백을 씁니다.
        /// (SignUp.jsx가 window.onNativeSignInError를 이미 쓰고 있어서, 그걸 재사용하면
        ///  StudentLinkScreen이 열려있는 동안 SignUp.jsx의 에러 핸들러를 덮어써버립니다.)
        private func sendLinkCodeResult(code: String?, uid: String?, name: String?, errorMessage: String?) {
            var payload: [String: Any] = [:]
            if let code {
                payload["code"] = code
            }
            
            if let uid {
                payload["uid"] = uid
            }
            
            if let name {
                payload["name"] = name
            }
            
            if let errorMessage {
                payload["message"] = errorMessage
            }
            
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
 
            let jsScript = """
                (function() {
                    window.onNativeLinkCodeResult && window.onNativeLinkCodeResult(\(jsonString));
                    return null;
                })();
                """
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsScript, completionHandler: nil)
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

extension SignUpView.Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // 카메라 촬영 완료
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        else {
            sendErrorToJS(provider: "profileImage", message: "이미지를 가져오지 못했습니다.", code: nil)
            return
        }
        sendPickedImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
extension SignUpView.Coordinator: PHPickerViewControllerDelegate {
    // 앨범에서 선택 완료
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard
            let provider = results.first?.itemProvider,
            provider.canLoadObject(ofClass: UIImage.self)
        else {
            return // 아무것도 선택 안 하고 닫은 경우
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.sendPickedImage(image)
            }
        }
    }
}

private extension UIImage {
/// 긴 변 기준 maxDimension을 넘지 않도록 축소합니다 (업로드/전송 용량 절약).
func resizedForUpload(maxDimension: CGFloat) -> UIImage? {
    let longestSide = max(size.width, size.height)
    guard longestSide > maxDimension else { return self }

    let scale = maxDimension / longestSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)

    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
        self.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
}

extension WKWebView {
    /// QR(유니버설 링크)로 앱이 열렸을 때, code/uid를 JS로 전달합니다.
    /// StudentLinkScreen 등에서 window.onNativeIncomingLinkCode로 받으면 됩니다.
    func notifyIncomingLinkCode(uid: String, name: String) {
#if DEBUG
        print("notifyIncomingLinkCode uid: \(uid), name: \(name)")
#endif
        let payload: [String: Any] = ["uid": uid, "name": name]
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else { return }
 
        let jsScript = """
            (function() {
                window.onNativeIncomingLinkCode && window.onNativeIncomingLinkCode(\(jsonString));
                return null;
            })();
            """
        evaluateJavaScript(jsScript, completionHandler: nil)
    }
}
