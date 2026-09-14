//
//  SchoolViewModel.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation
import Alamofire
import Combine
import RealmSwift
import FirebaseAuth
import FirebaseFirestore

class SchoolViewModel: ObservableObject {
    @Published var schoolInfo: SchoolResponseInfo? = nil
    @Published var isLoading: Bool = false
    private let db = Firestore.firestore()
    private var realm: Realm?
    
//    let schollInfoURL = "https://open.neis.go.kr/hub/schoolInfo?KEY=\(Config.authKey)&Type=json&pIndex=1&pSize=10"
    
    init() {}
    
    func fetchSchoolInfo(uid: String) async throws -> SchoolInfo? {
        let documentRef = db.collection("users").document(uid)
        let document = try await documentRef.getDocument()
        
        guard document.exists,
              let data = document.data(),
              let schoolInfo = data["schoolInfo"] as? [String: Any],
              let schoolName = schoolInfo["schoolName"] as? String,
              let address = schoolInfo["address"] as? String,
              let grade = schoolInfo["grade"] as? String
        else {
            return nil
        }
        
        return SchoolInfo(SCHUL_NM: schoolName, ORG_RDNMA: address, GRADE: grade)
    }
    
    func saveSchoolInfo(uid: String, schoolInfo: SchoolInfo) async throws {
        try await db.collection("users").document(uid).setData([
            "schoolInfo": [
                "schoolName": schoolInfo.SCHUL_NM,
                "address": schoolInfo.ORG_RDNMA,
                "grade": schoolInfo.GRADE,
                "tel": schoolInfo.ORG_TELNO,
                "schoolCode": schoolInfo.SD_SCHUL_CODE,         // 행정표준코드
                "schoolSCCode": schoolInfo.ATPT_OFCDC_SC_CODE,   // 시도교육청코드
                "createdAt": FieldValue.serverTimestamp()
            ]
        ])
    }
}
