//
//  RealmManager.swift
//  KidsFullCare
//
//  Created by najak on 7/28/26.
//

import RealmSwift
import Foundation

class RealmManager {
    static let shared = RealmManager()
    private init() {}
    
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.najak")
        let realmURL = container?.appendingPathComponent("kidsfullcare.realm")

#if DELETE_USE
        try! FileManager.default.removeItem(at: realmURL!)
#endif

        let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 1)
        return try! Realm(configuration: config)
    }
}
