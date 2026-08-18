//
//  AuthGateViewModel.swift
//  KidsFullCare
//
//  로그인 상태 + 역할(role) 정보를 관리하는 "단일 진실 공급원(Single Source of Truth)".
//  React(JS)는 이 상태를 그대로 받아서 화면만 그립니다.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AuthGateState: Equatable {
    case checking                                   // 최초 로그인 상태 확인 중 (스플래시)
    case loggedOut(returningUser: Bool)             // 로그인 안 됨. returningUser: 이 기기가 예전에 가입한 적 있는지
    case needsRole(name: String)                    // 로그인은 됐지만 역할(role) 미선택 → 역할 선택 화면
    case loginCancel
    case signUp
    case loggedIn(role: String)                     // 로그인 + 역할 선택까지 완료 → 메인 화면
}

enum AppleAuthState: Equatable {
    case authInit                       // 초기값
    case authorized                     // Apple ID 인증 성공(로그인 상태)
    case revoked                        // Apple ID 인증이 취소됨 (사용자가 설정에서 인증 해제 등...
    case notFound                       // Apple ID 자격 증명을 찾을 수 없음
    case unKnown                        // 알수 없는 상태 또는 오류 발생
}

@MainActor
final class AuthGateViewModel: ObservableObject {
    @Published private(set) var state: AuthGateState = .checking
    @Published var isAuthenticated: AppleAuthState = .authInit
    
    private nonisolated(unsafe) var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // 이게 이 아키텍처의 핵심입니다.
        // 앱이 켜질 때, 그리고 로그인/로그아웃이 일어날 때마다 자동으로 호출됩니다.
        
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
              let user = userInfo["firebaseUID"] as? String
        else {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
#if DEBUG
                print("Error signing out: %@", signOutError)
#endif
            }
            self.state = .signUp
            return
        }
        
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: user) { (state, error) in
            switch state {
            case .authorized:
#if DEBUG
                print("인증 유효")
#endif
            case .revoked, .notFound:
                Task { @MainActor in
                    self.resetDevice()
                }
            default: break
            }
        }
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task {
                await self?.handleAuthChange(user: user)
            }
        }
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        guard let user else {
            checkAppleSignInStatus { appleAuthState in
                Task {
                    if appleAuthState == .authorized {
                        self.state = .loggedOut(returningUser: await self.checkIsReturningUser())
                    } else {
                        self.state = .signUp
                    }
                }
            }
            return
        }

        var name: String = ""
        
        do {
            let snapshot = try await db.collection("users").document(user.uid).getDocument()
            name = snapshot.data()?["displayName"] as? String ?? ""
            if let role = snapshot.data()?["role"] as? String,
               !role.isEmpty {
                state = .loggedIn(role: role)
            } else {
                // 로그인은 됐는데 role 문서가 없음 → 역할 선택을 마저 해야 함
                // (예: 로그인 직후 앱이 종료되어 역할 선택을 못 마친 경우)
                state = .needsRole(name: name)
            }
        } catch {
            // 네트워크 오류 등으로 조회 실패 시, 일단 역할 선택 화면으로 보내고
            // 화면에서 재시도하도록 둡니다. 필요하면 별도 .error 상태를 추가해도 됩니다.
            state = .needsRole(name: name)
        }
    }
    
    /// Keychain에 저장된 마지막 로그인 uid가 실제로 Firestore에도 있는지 확인합니다.
    /// true면 "이 기기가 예전에 가입을 완료한 적이 있다"는 뜻으로,
    /// JS가 이메일/비밀번호 폼을 "로그인" 모드로 먼저 보여줄지 판단하는 데 씁니다.
    private func checkIsReturningUser() async -> Bool {
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
              let lastUid = userInfo["firebaseUID"] as? String
        else {
            return false
        }
        
        do {
            let snapshot = try await db.collection("users").document(lastUid).getDocument()
            return snapshot.exists
        } catch {
            // 조회 실패 시 굳이 사용자에게 잘못된 확신을 주지 않도록 false로 처리합니다.
            return false
        }
    }
    
    func checkAppleSignInStatus(completion: ((AppleAuthState) -> Void)? = nil) {
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
            let userID = userInfo["user"] as? String
        else {
            DispatchQueue.main.async {
                self.isAuthenticated = .authInit
                completion?(.authInit)
            }
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userID) { [weak self] (credentialState, error) in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
#if DEBUG
                    print("Apple ID 인증 성공(로그인 상태)")
#endif
                    self?.isAuthenticated = .authorized
                    completion?(.authorized)
                case .revoked:
#if DEBUG
                    print("Apple ID 인증이 취소됨 (사용자가 설정에서 인증 해제 등...)")
#endif
                    self?.isAuthenticated = .revoked
                    completion?(.revoked)
                case .notFound:
#if DEBUG
                    print("Apple ID 자격 증명을 찾을 수 없음")
#endif
                    self?.isAuthenticated = .notFound
                    completion?(.notFound)
                default:
#if DEBUG
                    print("알 수 없는 상태 또는 오류 발생: \(String(describing: error))")
#endif
                    self?.isAuthenticated = .unKnown
                    completion?(.unKnown)
                }
            }
        }
    }
    

    /// Apple 로그인 성공 후 identityToken + rawNonce로 Firebase에 직접 로그인합니다.
    /// 성공하면 addStateDidChangeListener가 자동으로 다시 트리거되어
    /// state가 .needsRole 또는 .loggedIn으로 바뀝니다.
    ///
    /// appleUserId는 authorizationController(didCompleteWithAuthorization:)에서 받은
    /// appleCredential.user 값입니다. Keychain에 저장해두면, 다음에 앱을 실행했을 때
    /// (로그아웃되어 있더라도) "이 기기가 예전에 가입한 적 있는지" 판단할 수 있습니다.
    func signInWithApple(identityToken: String, rawNonce: String, appleCredential: ASAuthorizationAppleIDCredential) async throws {
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: identityToken,
            rawNonce: rawNonce
        )
        
        // Firebase 로그인 (최초 접속 시 자동 회원가입)
        let result = try await Auth.auth().signIn(with: credential)
        
        let displayName = DeviceIdentifier.shared.setUserAppleID(appleCredential, result.user.uid)
        
        try await db.collection("users").document(result.user.uid).setData([
            "uid": result.user.uid,
            "appleUserId": appleCredential.user,
            "uuid": DeviceIdentifier.shared.getDeviceUUID(),
            "email": result.user.email ?? "",
            "displayName": result.user.displayName ?? displayName,
            "provider": "apple",
            "updatedAt": FieldValue.serverTimestamp(),
        ], merge: true)
        
    }

    /// 이메일/비밀번호로 신규 가입 (비밀번호 확인은 JS 쪽에서 이미 검증하고 넘어옵니다)
    func signUpWithEmail(name: String, email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
        
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        DeviceIdentifier.shared.setUserEmailID(name: name, email: email, firebaseUID: result.user.uid)
        
        try await db.collection("users").document(result.user.uid).setData([
            "uid": result.user.uid,
            "uuid": DeviceIdentifier.shared.getDeviceUUID(),
            "email": result.user.email ?? "",
            "displayName": result.user.displayName ?? name,
            "provider": "email",
            "updatedAt": FieldValue.serverTimestamp(),
        ], merge: true)
        
        state = .needsRole(name: name)
    }

    /// 이메일/비밀번호로 기존 계정 로그인
    func signInWithEmail(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    /// 학생용 6자리 연결 코드를 생성해서 linkCodes/{code} 문서를 만들고,
    /// users/{uid}에도 currentLinkCode로 표시해둡니다.
    /// (원래 JS의 generateLinkCode.js와 동일한 로직을 네이티브로 옮긴 버전입니다)
    func generateStudentLinkCode() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthGateViewModel", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "로그인이 필요합니다.",
            ])
        }
 
        let code = Self.randomSixDigitCode()
 
        try await db.collection("linkCodes").document(code).setData([
            "studentUid": user.uid,
            "createdAt": FieldValue.serverTimestamp(),
            "used": false,
        ])
 
        try await db.collection("users").document(user.uid).updateData([
            "currentLinkCode": code,
        ])
 
        return code
    }
    
    private static func randomSixDigitCode() -> String {
        String(Int.random(in: 100_000...999_999))
    }
    
    /// 역할 선택 화면에서 사용자가 학부모/학생을 고르면 호출합니다.
    func saveRole(_ role: String, extra: [String: Any] = [:]) async throws {
        guard let user = Auth.auth().currentUser else { return }

        
        let displayName = DeviceIdentifier.shared.getUserForKey("displayName") ?? ""
        
        var payload: [String: Any] = [
            "uid": user.uid,
            "role": role,
            "email": user.email ?? "",
            "displayName": user.displayName ?? displayName,
            "provider": user.providerData.first?.providerID ?? "unknown",
            "createdAt": FieldValue.serverTimestamp(),
        ]

        // uid/role/createdAt 등 예약 필드는 extra가 덮어쓰지 못하게 막습니다.
        let reservedKeys: Set<String> = ["uid", "role", "createdAt"]
        for (key, value) in extra where !reservedKeys.contains(key) {
            payload[key] = value
        }

        try await db.collection("users").document(user.uid).setData(payload, merge: true)

        // 다음 addStateDidChangeListener를 기다리지 않고 즉시 반영합니다.
        state = .loggedIn(role: role)
    }

    func signOut() {
        try? Auth.auth().signOut()
        // 리스너가 자동으로 .loggedOut으로 바꿔줍니다.
    }
    
    func resetDevice() {
        KeychainHelper.shared.delete(account: "userID")
        try? Auth.auth().signOut()
    }
}
