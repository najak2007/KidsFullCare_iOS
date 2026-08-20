//
//  FaceIDManager.swift
//  KidsFullCare
//
//  Created by najak on 8/20/26.
//

import SwiftUI
import LocalAuthentication
import Combine

enum BiometricUseState: String, Equatable {
    case 사용여부_질문필요
    case 사용하지_않음
    case 사용
    
}

class FaceIDManager: ObservableObject {
    @Published var isFaceIDChanged: Bool = false
    @Published var isFaceIDAuthSuccess: Bool = false
    
    private let SAVED_STATE_KEY = "SavedBiometricDomainState"
    private let USE_BIOMETRIC_KEY = "UseBiometricAuthentication"
    
    func authenticate(_ password: String = "", completion: @escaping (Bool, Data?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "로그인을 위해 인증하세요."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        if let currentState = context.domainState.biometry.stateHash {
                            let defaults = UserDefaults.standard
                            if let savedData = defaults.data(forKey: self.SAVED_STATE_KEY) {
                                if savedData != currentState {
                                    self.isFaceIDChanged = true
                                    DeviceIdentifier.shared.setUserPassword(savedData, nil)
                                    return completion(false, nil)
                                } else {
                                    if !password.isEmpty {
                                        DeviceIdentifier.shared.setUserPassword(currentState, password)
                                    }
                                    return completion(true, currentState)
                                }
                            } else {
                                defaults.set(currentState, forKey: self.SAVED_STATE_KEY)
                                if !password.isEmpty {
                                    DeviceIdentifier.shared.setUserPassword(currentState, password)
                                }
                                completion(true, currentState)
                            }
                        }
                        self.isFaceIDAuthSuccess = true
                    } else {
                        completion(false, nil)
                    }
                }
            }
        }
    }
    
}
