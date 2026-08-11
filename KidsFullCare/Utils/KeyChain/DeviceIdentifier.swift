//
//  DeviceIdentifier.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import Foundation
import AuthenticationServices

class DeviceIdentifier {
    static let shared = DeviceIdentifier()
    private init() {}
    
    private let keychainAccount = "deviceUUID"
    private let keychainUserID = "userID"
    private let keychainUID = "firebaseUID"
    
    // 기기 고유 UUID 가져오기 (없으면 새로 생성 후 저장)
    func getDeviceUUID() -> String {
        if let existingUUID = KeychainHelper.shared.read(account: keychainAccount) {
            return existingUUID
        }
        
        let newUUID = UUID().uuidString
        KeychainHelper.shared.save(newUUID, account: keychainAccount)
        return newUUID
    }
    
    func setUserID(_ appleCredential: ASAuthorizationAppleIDCredential) {
        guard let existingInfoStr = KeychainHelper.shared.read(account: keychainUserID)
        else {
            
            let userDict: [String: Any] = [
                "user": appleCredential.user,
                "name" : appleCredential.fullName ?? "",
                "email" : appleCredential.email ?? "",
                "ageRange" : appleCredential.userAgeRange.rawValue
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userDict, options: .prettyPrinted),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
            KeychainHelper.shared.save(jsonString, account: keychainUserID)
            return
        }
    }
    
    func getUserID() -> [String: Any]? {
        guard let existingInfoStr = KeychainHelper.shared.read(account: keychainUserID)
        else {
            return nil
        }

        guard let jsonData = existingInfoStr.data(using: .utf8)
        else {
            return nil
        }
        
        let userDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        return userDict
    }
    
    func getFirebaseUID() -> String? {
        return KeychainHelper.shared.read(account: keychainUID)
    }
    
    func setFirebaseUID(_ uid: String) {
        KeychainHelper.shared.save(uid, account: keychainUID)
    }
}
