//
//  StudentMenu.swift
//  KidsFullCare
//
//  Created by najak on 9/28/26.
//

import Foundation

struct StudentMenu: Codable, Identifiable {
    let key: String
    var label: String
    let icon: String
    let color: String
    var id: String { key }
    var register: Bool? = false
}
