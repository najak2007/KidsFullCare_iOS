//
//  KeychainHelper.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private let service: String = "com.sooyeon.lhhousenoti"
    private let account = "deviceUUID"
    
    func save(_ value: String, account: String) {
        let data = Data(value.utf8)

        // 기존 항목 삭제 (중복 방지)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        // 새 항목 추가
        var newItem = query
        newItem[kSecValueData as String] = data
        // 기기 잠금 해제 후에만 접근 가능 (보안 강화 옵션)
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newItem as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain 저장 실패: \(status)")
        }
    }

    /// Keychain에서 문자열 조회
    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    /// Keychain 항목 삭제
    func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
