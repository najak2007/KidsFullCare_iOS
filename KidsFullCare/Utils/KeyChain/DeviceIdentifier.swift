//
//  DeviceIdentifier.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import Foundation

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
    
    func setUserID(_ userID: String) {
        KeychainHelper.shared.save(userID, account: keychainUserID)
    }
    
    func getUserID() -> String? {
        return KeychainHelper.shared.read(account: keychainUserID)
    }
    
    func getFirebaseUID() -> String? {
        return KeychainHelper.shared.read(account: keychainUID)
    }
    
    func setFirebaseUID(_ uid: String) {
        KeychainHelper.shared.save(uid, account: keychainUID)
    }
}
