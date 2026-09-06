//
//  WebViewModel.swift
//  KidsFullCare
//
//  Created by najak on 9/2/26.
//

import SwiftUI
import WebKit
import Combine

struct MessageUserInfo: Codable {
    let uid: String
    let name: String
}

var chatViewController = PassthroughSubject<MessageUserInfo, Never>()

class WebViewModel: ObservableObject {
    var webView: WKWebView?
    
    func sendCallback(method: String, path: String, status: Int, payload: [String: Any]) {
        guard let webView = webView else { return }
        
        let responseDict: [String: Any] = [
            "method": method,       // "POST" 또는 "PUT"
            "path": path,           // 요청 경로
            "status": status,       // HTTP 상태 코드
            "payload": payload      // 데이터 Body
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseDict, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // CustomEvent를 발화시키는 JS Script 작성
                let script = "window.dispatchEvent(new CustomEvent('NativeBridgeResponse', { detail: \(jsonString) }));"
                
                DispatchQueue.main.async {
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            print("JS 실행 에러: \(error.localizedDescription)")
                        } else {
                            print("JS 콜백 전송 성공 [\(method)]")
                        }
                    }
                }
            }
        } catch {
            print("JSON 변환 실패: \(error)")
        }
    }
}

extension WebViewModel {
    func handlePushNavigation(userInfo: MessageUserInfo) {
    }
}
