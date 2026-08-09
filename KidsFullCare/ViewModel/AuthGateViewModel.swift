//
//  AuthGateViewModel.swift
//  KidsFullCare
//
//  로그인 상태 + 역할(role) 정보를 관리하는 "단일 진실 공급원(Single Source of Truth)".
//  React(JS)는 이 상태를 그대로 받아서 화면만 그립니다.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AuthGateState: Equatable {
    case checking                  // 최초 로그인 상태 확인 중 (스플래시)
    case loggedOut                 // 로그인 안 됨 → Sign in with Apple 화면
    case needsRole                 // 로그인은 됐지만 역할(role) 미선택 → 역할 선택 화면
    case loginCancel
    case loggedIn(role: String)    // 로그인 + 역할 선택까지 완료 → 메인 화면
}

@MainActor
final class AuthGateViewModel: ObservableObject {
    @Published private(set) var state: AuthGateState = .checking

    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // 이게 이 아키텍처의 핵심입니다.
        // 앱이 켜질 때, 그리고 로그인/로그아웃이 일어날 때마다 자동으로 호출됩니다.
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { await self?.handleAuthChange(user: user) }
        }
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        guard let user else {
            state = .loggedOut
            return
        }

        do {
            let snapshot = try await db.collection("users").document(user.uid).getDocument()
            if let role = snapshot.data()?["role"] as? String, !role.isEmpty {
                state = .loggedIn(role: role)
            } else {
                // 로그인은 됐는데 role 문서가 없음 → 역할 선택을 마저 해야 함
                // (예: 로그인 직후 앱이 종료되어 역할 선택을 못 마친 경우)
                state = .needsRole
            }
        } catch {
            // 네트워크 오류 등으로 조회 실패 시, 일단 역할 선택 화면으로 보내고
            // 화면에서 재시도하도록 둡니다. 필요하면 별도 .error 상태를 추가해도 됩니다.
            state = .needsRole
        }
    }

    /// Apple 로그인 성공 후 identityToken + rawNonce로 Firebase에 직접 로그인합니다.
    /// 성공하면 addStateDidChangeListener가 자동으로 다시 트리거되어
    /// state가 .needsRole 또는 .loggedIn으로 바뀝니다.
    func signInWithApple(identityToken: String, rawNonce: String, appleUserId: String) async throws {
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: identityToken,
            rawNonce: rawNonce
        )
        let result = try await Auth.auth().signIn(with: credential)
        
        DeviceIdentifier.shared.setUserID(appleUserId)
        DeviceIdentifier.shared.setFirebaseUID(result.user.uid)
        
        try await db.collection("users").document(result.user.uid).setData([
            "uid": result.user.uid,
            "appleUserId": appleUserId,
            "uuid": DeviceIdentifier.shared.getDeviceUUID(),
            "email": result.user.email ?? "",
            "name": result.user.displayName ?? "",
            "provider": "apple.com",
            "updatedAt": FieldValue.serverTimestamp(),
        ], merge: true)
        
    }

    /// 이메일/비밀번호로 신규 가입 (비밀번호 확인은 JS 쪽에서 이미 검증하고 넘어옵니다)
    func signUpWithEmail(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    /// 이메일/비밀번호로 기존 계정 로그인
    func signInWithEmail(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    /// 역할 선택 화면에서 사용자가 학부모/학생을 고르면 호출합니다.
    func saveRole(_ role: String) async throws {
        guard let user = Auth.auth().currentUser
        else {
                print("Error: Firebase Auth currentUser가 null입니다.")
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "로그인된 사용자가 없습니다."])
        }

        // merge: true 옵션 제거 (create 규칙 적용)
        try await db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "role": role,
            "email": user.email ?? "",
            "name": user.displayName ?? "",
            "provider": user.providerData.first?.providerID ?? "unknown",
            "createdAt": FieldValue.serverTimestamp(),
        ])

        state = .loggedIn(role: role)
    }

    func signOut() {
        try? Auth.auth().signOut()
        // 리스너가 자동으로 .loggedOut으로 바꿔줍니다.
    }
}
