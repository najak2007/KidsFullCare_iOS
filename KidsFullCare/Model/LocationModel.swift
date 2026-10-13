//
//  LocationInfoData.swift
//  KidsFullCare
//
//  Created by najak on 10/13/26.
//

import Foundation
import RealmSwift

class LocationInfoData: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var address: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var alias: String = "집"
}

class UserPlaceInfoData: Object, Comparable {
    @objc dynamic var id: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var address: String = ""
    @objc dynamic var inDate: Date = Date()
    @objc dynamic var outDate: Date = Date()
    @objc dynamic var alias: String = ""
    @objc dynamic var isInitStatus: Bool = true
    @objc dynamic var orderByIndex: Int = 0
    @objc dynamic var isNearBy: Bool = false
    @objc dynamic var isDelete: Bool = false
    
    static func < (lhs: UserPlaceInfoData, rhs: UserPlaceInfoData) -> Bool {
        return lhs.orderByIndex < rhs.orderByIndex
    }
}

struct SearchLocationDataInfo {
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var userPlaceInfoData: UserPlaceInfoData?
    
    init() {}
    
    init (latitude: Double?, longitude: Double?, address: String?, userPlaceInfoData: UserPlaceInfoData? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.userPlaceInfoData = userPlaceInfoData
    }
    
    mutating func update(latitude: Double?, longitude: Double?, address: String?, userPlaceInfoData: UserPlaceInfoData? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.userPlaceInfoData = userPlaceInfoData
    }
}
