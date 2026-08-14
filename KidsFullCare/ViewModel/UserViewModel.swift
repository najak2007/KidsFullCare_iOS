//
//  UserViewModel.swift
//  KidsFullCare
//
//  Created by najak on 7/28/26.
//

import SwiftUI
import Combine
import RealmSwift
import WebKit
internal import Realm
import FirebaseAuth


class UserViewModel: ObservableObject {
    
    private var realm: Realm?
    weak var webView: WKWebView?
    
    @Published var deviceUUID: String = ""
    @Published var pushToken: String = ""
    var name: String {
        get {
            return DeviceIdentifier.shared.getUserForKey("displayName") ?? ""
        }
    }
    
    init() {
        realm = RealmManager.shared.realm
        deviceUUID = DeviceIdentifier.shared.getDeviceUUID()
    }
    
    func sendDeviceInfoToWeb() {
        let token = pushToken.isEmpty ? "" : pushToken
        
        guard let uuidData = try? JSONEncoder().encode(deviceUUID),
              let tokenData = try? JSONEncoder().encode(token),
              let uuidJSON = String(data: uuidData, encoding: .utf8),
              let tokenJSON = String(data: tokenData, encoding: .utf8)
        else {
            return
        }
        
        let script = "if(window.receiveDeviceInfo) { window.receiveDeviceInfo(\(uuidJSON), \(tokenJSON)) }"
        
        webView?.evaluateJavaScript(script) { _, error in
            if let error = error {
                #if DEBUG
                print("JS 호출 에러 : \(error.localizedDescription)")
                #endif
            }
        }
    }
}
