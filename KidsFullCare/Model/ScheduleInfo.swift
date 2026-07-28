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

struct SchoolResponseInfo: Codable {
    var ATPT_OFCDC_SC_CODE: String = ""                     // 시도교육청코드
    var ATPT_OFCDC_SC_NM: String = ""                       // 시도교육청명
    var SD_SCHUL_CODE: String = ""                          // 행정표준코드
    var SCHUL_NM: String = ""                               // 학교명
    var ENG_SCHUL_NM: String = ""                           // 영문학교명
    var SCHUL_KND_SC_NM: String = ""                        // 학교종류명
    var LCTN_SC_NM: String = ""                             // 시도명
    var JU_ORG_NM: String = ""                              // 관할조직명
    var FOND_SC_NM: String = ""                             // 설립명
    var ORG_RDNZC: String = ""                              // 도로명우편번호
    var ORG_RDNMA: String = ""                              // 도로명주소
    var ORG_RDNDA: String = ""                              // 도로명상세주소
    var ORG_TELNO: String = ""                              // 전화번호
    var HMPG_ADRES: String = ""                             // 홈페이지주소
    var COEDU_SC_NM: String = ""                            // 남녀공학구분명
    var ORG_FAXNO: String = ""                              // 팩스번호
    var HS_SC_NM: String = ""                               // 고등학교구분명
    var INDST_SPECL_CCCCL_EXST_YN: String = ""              // 산업체특별학급존재여부
    var HS_GNRL_BUSNS_SC_NM: String = ""                    // 고등학교일반전문구분명
    var SPCLY_PURPS_HS_ORD_NM: String = ""                  // 특수목적고등학교계열명
    var ENE_BFE_SEHF_SC_NM: String = ""                     // 입시전후기구분명
    var DGHT_SC_NM: String = ""                             // 주야구분명
    var FOND_YMD: String = ""                               // 설립일자
    var FOAS_MEMRD: String = ""                             // 개교기념일
    var LOAD_DTM: String = ""                               // 수정일자
}

class SchoolInfoData: Object, Comparable, Identifiable {
    @Persisted dynamic var id: String = "School\(Date().getDataID())"
    @Persisted dynamic var ATPT_OFCDC_SC_CODE: String = ""              // 시도교육청코드
    @Persisted dynamic var SD_SCHUL_CODE: String = ""                   // 행정표준코드
    @Persisted dynamic var SCHUL_NM: String = ""                        // 학교명
    @Persisted dynamic var SCHUL_KND_SC_NM: String = ""                 // 학교종류명
    @Persisted dynamic var LCTN_SC_NM: String = ""                      // 시도명
    @Persisted dynamic var FOND_SC_NM: String = ""                      // 설립명
    @Persisted dynamic var registerDate: Date = Date()
    
    static func < (lhs: SchoolInfoData, rhs: SchoolInfoData) -> Bool {
        return lhs.registerDate < rhs.registerDate
    }
}
