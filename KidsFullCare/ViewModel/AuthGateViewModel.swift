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

var bioAuthRequest = PassthroughSubject<String, Never>()
var loginSuccess: PassthroughSubject<Bool, Never> = .init()

enum AuthGateState: Equatable {
    case checking                                   // 최초 로그인 상태 확인 중 (스플래시)
    case loggedOut(returningUser: Bool, provider: String)             // 로그인 안 됨. returningUser: 이 기기가 예전에 가입한 적 있는지
    case needsRole(name: String)                    // 로그인은 됐지만 역할(role) 미선택 → 역할 선택 화면
    case loginCancel
    case signUp
    case loggedIn(role: String, profileImg: String)                     // 로그인 + 역할 선택까지 완료 → 메인 화면
}

enum AppleAuthState: Equatable {
    case authInit                       // 초기값
    case authorized                     // Apple ID 인증 성공(로그인 상태)
    case revoked                        // Apple ID 인증이 취소됨 (사용자가 설정에서 인증 해제 등...
    case notFound                       // Apple ID 자격 증명을 찾을 수 없음
    case unKnown                        // 알수 없는 상태 또는 오류 발생
}

enum AddFamilyState: Equatable {
    case 추가
    case 중복
    case 에러
}

@MainActor
final class AuthGateViewModel: ObservableObject {
    @Published private(set) var state: AuthGateState = .checking
    @Published var isAuthenticated: AppleAuthState = .authInit
    @Published var isReseting : Bool = false
    
    private nonisolated(unsafe) var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // 이게 이 아키텍처의 핵심입니다.
        // 앱이 켜질 때, 그리고 로그인/로그아웃이 일어날 때마다 자동으로 호출됩니다.
        
//       KeychainHelper.shared.delete(account: "userID")
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task {
                await self?.handleAuthChange(user: user)
            }
        }
        
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
              let _ = userInfo["firebaseUID"] as? String,
              let provider = userInfo["provider"] as? String
        else {
            do {
                try Auth.auth().signOut()
            } catch let signOutError as NSError {
#if DEBUG
                print("Error signing out: %@", signOutError)
#endif
            }
            self.isUseBiometricAck = .사용여부_질문필요
            self.state = .signUp
            return
        }
        
        if provider == "apple" {
            if let user = userInfo["user"] as? String {
                ASAuthorizationAppleIDProvider().getCredentialState(forUserID: user) { (state, error) in
                    switch state {
                    case .authorized:
#if DEBUG
                        print("인증 유효")
#endif
                    case .revoked, .notFound:
                        Task { @MainActor in
                            try await self.resetDevice()
                        }
                    default: break
                    }
                }
            }
        }
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        if isReseting {
            return
        }

        guard let user else {
            checkAppleSignInStatus { appleAuthState in
                Task {
                    if appleAuthState == .authorized {
                        self.state = self.checkIsReturningUser()
                    } else {
                        self.isUseBiometricAck = .사용여부_질문필요
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
                state = .loggedIn(role: role, profileImg: DeviceIdentifier.shared.getProfileImage(user.uid))
                loginSuccess.send(true)
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
    private func checkIsReturningUser() -> AuthGateState {
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
              let _ = userInfo["firebaseUID"] as? String,
              let provider = userInfo["provider"] as? String
        else {
            self.isUseBiometricAck = .사용여부_질문필요
            return .signUp
        }
        return .loggedOut(returningUser: true, provider: provider)
    }
    
    func checkAppleSignInStatus(completion: ((AppleAuthState) -> Void)? = nil) {
        guard let userInfo = DeviceIdentifier.shared.getUserID(),
            let _ = userInfo["firebaseUID"] as? String,
            let provider = userInfo["provider"] as? String
        else {
            DispatchQueue.main.async {
                self.isAuthenticated = .authInit
                completion?(.authInit)
            }
            return
        }
        
        if provider == "apple" {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            if let userID = userInfo["user"] as? String {
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
            } else {
                self.isAuthenticated = .unKnown
                completion?(.unKnown)
            }
        } else if provider == "email" {
            isAuthenticated = .authorized
            completion?(.authorized)
        } else {
            isAuthenticated = .unKnown
            completion?(.unKnown)
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
        
        let displayName = DeviceIdentifier.shared.setUserAppleID(appleCredential, identityToken, rawNonce, result.user.uid)
        
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
        
        if self.isUseBiometricAck == .사용여부_질문필요 {
            bioAuthRequest.send(password)
        }
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
    
    func fetchFamily(uid: String, familyUid: String,  completion: @escaping(Bool) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if error == nil {
                guard let document = snapshot, document.exists,
                      let data = document.data()
                else {
                    return
                }
                    
                if let familyArray = data["family"] as? [String] {
                    if familyArray.isEmpty {
                        completion(false)
                    } else {
                        let hasMatchingUid = familyArray.contains { element in
                            element.contains(familyUid)
                        }
                        
                        return completion(hasMatchingUid)
                    }
                }
            }
            completion(false)
        }
    }
    
    func addFamily(familyUid: String, familyName: String?, completion: @escaping(AddFamilyState) -> Void) {
        guard let user = Auth.auth().currentUser
        else {
            return completion(.에러)
        }
        
        self.fetchFamily(uid: user.uid, familyUid: familyUid) { isExists in
            if !isExists {
                Task {
                    let familyInfo: String = "\(familyUid):\(familyName ?? "")"
                    try await self.db.collection("users").document(user.uid).updateData([
                        "family": FieldValue.arrayUnion([familyInfo])
                    ])
                    return completion(.추가)
                }
            }
            return completion(.중복)
        }
    }
    
    func fetchStudentInfo(studentUid: String) async throws -> String? {
        let documentRef = db.collection("users").document(studentUid)
        let document = try await documentRef.getDocument()
        
        guard document.exists,
              let data = document.data(),
              let displayName = data["displayName"] as? String
        else {
            return nil
        }
            
        return displayName
    }
    
    func fetchStudentForCodeWithUid(code: String, uid: String, parentUid: String) async throws -> (Bool, String)? {
        let documentRef = db.collection("linkCodes").document(code)
        let document = try await documentRef.getDocument()

        guard document.exists,
              let data = document.data(),
              let studentUid = data["studentUid"] as? String,
              studentUid == uid,
              let createdAt = data["createdAt"] as? Timestamp,
              let used = data["used"] as? Bool
        else {
#if DEBUG
            print("동일한 코드를 찾지 못했습니다.")
#endif
            return (false, "동일한 코드를 찾지 못했습니다.")
        }

        let expirationThreshold = Date().addingTimeInterval(-130) // 2분 + 10초 여유
        guard createdAt.dateValue() > expirationThreshold else {
#if DEBUG
            print("코드가 만료되었습니다.")
#endif
            return (false, "코드가 만료되었습니다.")
        }

        if used {
#if DEBUG
            print("이미 사용된 코드입니다.")
#endif
            return (false, "이미 사용된 코드입니다.")
        }
                
        try await documentRef.updateData([
            "parent": FieldValue.arrayUnion([parentUid]),
            "used": true
        ])

        return (true, studentUid)
    }
    
    private static func randomSixDigitCode() -> String {
        String(Int.random(in: 100_000...999_999))
    }
    
    /// 역할 선택 화면에서 사용자가 학부모/학생을 고르면 호출합니다.
    func saveRole(_ role: String, extra: [String: Any] = [:]) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        var payload: [String: Any] = [
            "role": role,
        ]

        // uid/role/createdAt 등 예약 필드는 extra가 덮어쓰지 못하게 막습니다.
        let reservedKeys: Set<String> = ["uid", "role", "createdAt"]
        for (key, value) in extra where !reservedKeys.contains(key) {
            payload[key] = value
        }

        try await db.collection("users").document(user.uid).setData(payload, merge: true)

        state = .loggedIn(role: role, profileImg: DeviceIdentifier.shared.getProfileImage(user.uid))
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        // 리스너가 자동으로 .loggedOut으로 바꿔줍니다.
    }

    func autoSignIn() async throws {
        guard  let _ = Auth.auth().currentUser?.uid
        else {
            if let provider = DeviceIdentifier.shared.getUserForKey("provider") {
                if provider == "apple" {
                    if let idToken = DeviceIdentifier.shared.getUserForKey("idToken"),
                       let rawNonce = DeviceIdentifier.shared.getUserForKey("rawNonce") {
                        let credential = OAuthProvider.credential(
                            providerID: .apple,
                            idToken: idToken,
                            rawNonce: rawNonce
                        )
                        try await Auth.auth().signIn(with: credential)
                    }
                } else if provider == "email" {
                    if let faceID = DeviceIdentifier.shared.faceID,
                       let password = DeviceIdentifier.shared.getUserPassword(faceID),
                       let email = DeviceIdentifier.shared.getUserForKey("email") {
                            try await Auth.auth().signIn(withEmail: email, password: password)
                        }
                }
            }
            return
        }
    }
    
    func resetDevice() async throws {
        isReseting = true
        if let provider = DeviceIdentifier.shared.getUserForKey("provider") {
            if provider == "apple" {
                if let idToken = DeviceIdentifier.shared.getUserForKey("idToken"),
                   let rawNonce = DeviceIdentifier.shared.getUserForKey("rawNonce") {
                    let credential = OAuthProvider.credential(
                        providerID: .apple,
                        idToken: idToken,
                        rawNonce: rawNonce
                    )
                    try await Auth.auth().signIn(with: credential)
                    if let user = Auth.auth().currentUser {
                        DeviceIdentifier.shared.setProfileImage(user.uid, nil)
                    }
                    if let uid = Auth.auth().currentUser?.uid {
                        try await Firestore.firestore().collection("users").document(uid).delete()
                    }
                    try await Auth.auth().currentUser?.reauthenticate(with: credential)

                    do {
                        try await Auth.auth().currentUser?.delete()
                    } catch {
#if DEBUG
                        print("삭제 실패 :", error.localizedDescription)
#endif
                        isReseting = false
                    }

                    KeychainHelper.shared.delete(account: "userID")

                    try? Auth.auth().signOut()
                    self.isUseBiometricAck = .사용여부_질문필요
                    isReseting = false
                    state = .signUp
                }
            } else if provider == "google" {
                
            } else if provider == "email" {
                if let faceID = DeviceIdentifier.shared.faceID,
                   let password = DeviceIdentifier.shared.getUserPassword(faceID),
                   let email = DeviceIdentifier.shared.getUserForKey("email") {
             
                    // 방금 로그인했으니 이미 "최근 인증됨" 상태입니다.
                    // 로그인 직후 다시 reauthenticate하는 건 중복이라 뺐습니다.
                    try await Auth.auth().signIn(withEmail: email, password: password)
             
                    guard let user = Auth.auth().currentUser else { return }
                    let uid = user.uid
             
                    DeviceIdentifier.shared.setProfileImage(uid, nil)
             
                    // 1) Firestore 문서 삭제 (계정이 아직 살아있는 상태에서 먼저)
                    try await Firestore.firestore().collection("users").document(uid).delete()
             
                    // 2) Auth 계정 삭제
                    //    여기서 실패하면 절대로 아래(Keychain 삭제/로그아웃/state 전환)를
                    //    실행하면 안 됩니다. 계정은 Firebase에 그대로 남아있는데
                    //    앱만 "탈퇴 완료"인 것처럼 굴면, 다음에 로그인 시도 시
                    //    Firestore 문서는 없고 Auth 계정만 살아있는 불일치 상태가 됩니다.
                    do {
                        try await user.delete()
                    } catch {
            #if DEBUG
                        print("Auth 계정 삭제 실패:", error.localizedDescription)
            #endif
                        isReseting = false
                        throw error // 상위 호출부(에러 알림 UI 등)로 실패를 전달합니다.
                    }
             
                    // 여기까지 왔다는 건 Firestore + Auth 삭제가 전부 확실히 성공했다는 뜻입니다.
                    KeychainHelper.shared.delete(account: "userID")
                    try? Auth.auth().signOut()
                    self.isUseBiometricAck = .사용여부_질문필요
                    isReseting = false
                    state = .signUp
                }
            }
        }
    }
    
    var isUseBiometricAck: BiometricUseState {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "isUseBiometric")
        }
        get {
            if let biometicsValue = UserDefaults.standard.string(forKey: "isUseBiometric") {
                return BiometricUseState(rawValue: biometicsValue) ?? .사용여부_질문필요
            }
            return .사용여부_질문필요
        }
    }
}
