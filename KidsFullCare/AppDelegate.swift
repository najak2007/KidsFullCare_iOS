//
//  AppDelegate.swift
//  KidsFullCare
//
//  Created by najak on 7/20/26.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import FirebaseAppCheck
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
#if DEBUG
        // 개발/테스트 환경용 디버그 제공업체
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
#else
        // 실기기 / 배포용 App Attest 제공업체 설정
        if #available(iOS 14.0, *) {
            let providerFactory = AppAttestProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
        } else {
            // iOS 14 미만 대응용 DeviceCheck
            let providerFactory = DeviceCheckProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
        }
#endif

        Messaging.messaging().delegate = NotificationManager.shared
        
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            print("알림 권한: \(granted ? "허용" : "거부")")
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }
    
    // 2. 푸시 등록 성공 시 호출 (디바이스 토큰 수신)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Data 타입의 토큰을 String 형태로 변환
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        // 💡 콘솔에서 토큰을 확인하거나 서버(APNs/Firebase 등)로 전송하세요.
        print("✅ 성공: 푸시 디바이스 토큰 -> \(tokenString)")
        Messaging.messaging().apnsToken = deviceToken
    }
        
    // 3. 푸시 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ 실패: 원격 알림 등록에 실패했습니다: \(error.localizedDescription)")
    }
    // 4. 앱이 포그라운드(실행 중) 상태일 때 푸시가 오면 처리하는 옵션 (선택 사항)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 켜져 있을 때도 배너와 소리가 나도록 설정
        completionHandler([.banner, .list, .sound])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 데이터 처리 로직 수행
        print("didReceiveRemoteNotification called: \(userInfo)")
        
        // 작업 완료 상태 전달 (newData, noData, failed)
        completionHandler(.newData)
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {}
