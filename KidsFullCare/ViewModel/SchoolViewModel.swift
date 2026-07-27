//
//  SchoolViewModel.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import Foundation
import Alamofire
import Combine

class SchoolViewModel: ObservableObject {
    @Published var schoolInfo: SchoolResponseInfo? = nil
    @Published var isLoading: Bool = false
    
    let schollInfoURL = "https://open.neis.go.kr/hub/schoolInfo?KEY=\(Config.authKey)&Type=json&pIndex=1&pSize=10"
    
}
