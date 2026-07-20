//
//  NotificationManager.swift
//  LHHouseNoti
//
//  Created by najak on 7/18/26.
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import Combine
import FirebaseRemoteConfig

class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var fcmToken: String = ""
    
    private override init() {}

    // 현재 FCM 토큰 즉시 가져오기
    func fetchCurrentToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM 토큰 조회 실패: \(error.localizedDescription)")
                return
            }
            guard let token = token else { return }
            DispatchQueue.main.async {
                self.fcmToken = token
            }
            print("현재 FCM 토큰: \(token)")
            self.saveTokenToFirestore(token)
        }
    }
}

// MARK: - FCM 토큰 관리
extension NotificationManager: MessagingDelegate {

    // 토큰 자동 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        DispatchQueue.main.async {
            self.fcmToken = token
        }

        print("FCM 토큰 갱신: \(token)")

        // Firestore에 저장 (서버 없이 Firebase만 사용하는 경우)
        saveTokenToFirestore(token)
    }

    private func saveTokenToFirestore(_ token: String) {
        let dataDict: [String: String] = ["token": token]
        NotificationCenter.default.post(
            name: NSNotification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: dataDict
        )
        guard let userId = Auth.auth().currentUser?.uid else {
            print("로그인 유저 없음 → 토큰 저장 생략")
            return
        }

        print("userId = \(userId)")
        
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .setData( [
                "fcmToken": token,
                "uuid": DeviceIdentifier.shared.getDeviceUUID(),
                "platform": "i"
            ], merge: true) { error in
                if let error = error {
                    print("Firestore 토큰 저장 실패: \(error.localizedDescription)")
                } else {
                    print("Firestore 토큰 저장 완료 ✅")
                }
            }
    }
}

// MARK: - 알림 수신 처리
extension NotificationManager: UNUserNotificationCenterDelegate {

    // 포그라운드 알림 수신
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭 시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        PendingPushNavigation.payload = userInfo
        
        NotificationCenter.default.post(
            name: NSNotification.Name(Config.PUSH_NOTIFICATION_SELECTED_ID),
            object: nil,
            userInfo: userInfo
        )


        print("알림 탭: \(userInfo)")
        completionHandler()
    }
}
