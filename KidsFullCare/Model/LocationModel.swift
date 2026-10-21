//
//  LocationInfoData.swift
//  KidsFullCare
//
//  Created by najak on 10/13/26.
//

import Foundation
import RealmSwift

struct NearByPlaceInfoData {
    var placeDataInfo: UserPlaceInfoData?
    var isPushShow: Bool = true
    var isBadgeInit: Bool = false
}

class LocationInfoData: Object {
    @Persisted dynamic var id: String = ""
    @Persisted dynamic var latitude: Double = 0
    @Persisted dynamic var longitude: Double = 0
    @Persisted dynamic var address: String = ""
    @Persisted dynamic var date: Date = Date()
    @Persisted dynamic var alias: String = "집"
    @Persisted dynamic var name: String = ""
    @Persisted dynamic var isNearBy: Bool = false
    
    @Persisted dynamic var attendDate: List<Date> = List<Date>()
    @Persisted dynamic var leaveDate: List<Date> = List<Date>()
    
    
    init() {}
    
    convenience init(id: String,
                     latitude: Double,
                     longitude: Double,
                     address: String,
                     alias: String = "집",
                     name: String = "",
                     date: Date = Date(),
                     isNearBy: Bool = false) {
        self.init()
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.alias = alias
        self.date = date
        self.name = name
        self.isNearBy = isNearBy
    }
}

class UserPlaceInfoData: Object, Comparable {
    @Persisted dynamic var id: String = ""
    @Persisted dynamic var latitude: Double = 0
    @Persisted dynamic var longitude: Double = 0
    @Persisted dynamic var address: String = ""
    @Persisted dynamic var inDate: Date = Date()
    @Persisted dynamic var outDate: Date = Date()
    @Persisted dynamic var alias: String = ""
    @Persisted dynamic var isInitStatus: Bool = true
    @Persisted dynamic var orderByIndex: Int = 0
    @Persisted dynamic var isNearBy: Bool = false
    @Persisted dynamic var isDelete: Bool = false
    
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
