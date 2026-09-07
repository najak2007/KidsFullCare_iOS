//
//  ChatMessage.swift
//  KidsFullCare
//
//  Created by najak on 9/6/26.
//

import SwiftUI
import Foundation
import RealmSwift

struct UserInfo: Codable, Hashable {
    let userId: String
    let userName: String
    let profileImgBase64: String
    
    var profieImage: UIImage? {
        guard !profileImgBase64.isEmpty,
            let cleanBase64 = profileImgBase64.components(separatedBy: ",").last,
            let imageData = Data(base64Encoded: cleanBase64)
        else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    // 기본 생성자
    init(userId: String, userName: String, profileImgBase64: String) {
        self.userId = userId
        self.userName = userName
        self.profileImgBase64 = profileImgBase64
    }
}

class ChatUserInfo: Object {
    @Persisted dynamic var uid: String = ""
    @Persisted dynamic var name: String = ""
}

class ChatMessage: Object, Identifiable, Comparable {
    @Persisted dynamic var id = Date().getMessageID()
    @Persisted dynamic var userUid: String
    @Persisted dynamic var userName: String
    @Persisted dynamic var text: String
    @Persisted dynamic var isMine: Bool = false
    @Persisted dynamic var isRead: Bool = false
    @Persisted dynamic var date: Date = Date()

    static func < (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func > (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.date > rhs.date
    }
}

class ChatRoom: Object, Identifiable, Comparable {
    @Persisted dynamic var id = Date().getMessageID()
    @Persisted dynamic var users: RealmSwift.List<ChatUserInfo> = RealmSwift.List<ChatUserInfo>()
    @Persisted dynamic var messages: RealmSwift.List<ChatMessage> = RealmSwift.List<ChatMessage>()
    @Persisted dynamic var date: Date = Date()
    @Persisted dynamic var title: String = ""
    
    static func < (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func > (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.date > rhs.date
    }
}
