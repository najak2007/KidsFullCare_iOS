//
//  ScheduleInfo.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation
import RealmSwift


struct ScheduleInfo: Codable, Hashable {
    var id: String = UUID().uuidString
    let schedule: Date
    let isActive: Bool
}


