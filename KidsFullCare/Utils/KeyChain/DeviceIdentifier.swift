//
//  DeviceIdentifier.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import Foundation
import AuthenticationServices
import FirebaseFirestore

class DeviceIdentifier {
    static let shared = DeviceIdentifier()
    private init() {}
    
    private let keychainAccount = "deviceUUID"
    private let keychainUserID = "userID"
    
    // 기기 고유 UUID 가져오기 (없으면 새로 생성 후 저장)
    func getDeviceUUID() -> String {
        if let existingUUID = KeychainHelper.shared.read(account: keychainAccount) {
            return existingUUID
        }
        
        let newUUID = UUID().uuidString
        KeychainHelper.shared.save(newUUID, account: keychainAccount)
        return newUUID
    }
    
    func setUserAppleID(_ appleCredential: ASAuthorizationAppleIDCredential, _ firebaseUID: String = "") -> String {
        guard let userInfo = self.getUserID()
        else {
            var displayName: String = ""
            if let fullName = appleCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                formatter.style = .default
                displayName = formatter.string(from: fullName)
            }
            let userDict: [String: Any] = [
                "user": appleCredential.user,
                "displayName" : displayName,
                "email" : appleCredential.email ?? "",
                "ageRange" : appleCredential.userAgeRange.rawValue,
                "firebaseUID" : firebaseUID
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userDict, options: .prettyPrinted),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return displayName
            }
            KeychainHelper.shared.save(jsonString, account: keychainUserID)
            return displayName
        }
        
        if !firebaseUID.isEmpty, firebaseUID == userInfo["firebaseUID"] as? String {
            
        }
        
        return ""
    }
    
    func setUserEmailID(name: String, email: String, firebaseUID: String = "") {
        guard let userInfo = self.getUserID()
        else {
            let userDict: [String: Any] = [
                "email": email,
                "firebaseUID": firebaseUID,
                "provider": "email",
                "displayName": name
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userDict, options: .prettyPrinted),
                  let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return
            }
            KeychainHelper.shared.save(jsonString, account: keychainUserID)
            return
        }
        
        if userInfo["email"] as? String != email {
            /// 기존 저장된 이메일과 다른 정보가 있다.
            /// 어떤 처리를 해야 할까?
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
    
    func getUserForKey(_ key: String) -> String? {
        return getUserID()?[key] as? String
    }
}
