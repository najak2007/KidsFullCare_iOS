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


class UserViewModel: ObservableObject {
    
    private var realm: Realm?
    weak var webView: WKWebView?
    
    init() {
        realm = RealmManager.shared.realm
    }
}
