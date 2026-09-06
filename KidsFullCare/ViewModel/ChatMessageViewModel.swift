//
//  ChatMessageViewModel.swift
//  KidsFullCare
//
//  Created by najak on 9/6/26.
//

import Foundation
import Combine
import RealmSwift

final class ChatMessageViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var realm: Realm?
    
    init() {
        realm = RealmManager.shared.realm
    }
    
    func send(_ text: String) {
        
    }
}
