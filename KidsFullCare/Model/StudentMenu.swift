//
//  StudentMenu.swift
//  KidsFullCare
//
//  Created by najak on 9/28/26.
//

import Foundation
import RealmSwift

struct StudentMenu: Codable, Identifiable {
    let key: String
    var label: String
    let icon: String
    let color: String
    var id: String { key }
    var register: Bool? = false
}


struct SchoolInfo: Codable {
    var KEY: String = ""                                // Firestore - document - field 이름 ==> 예) school, academy...
    var SCHUL_NM: String = ""                           // 학교명
    var ORG_RDNMA: String = ""                          // 도로 주소
    var ORG_RDNDA: String = ""                          // 도로 상세 주소
    var ATPT_OFCDC_SC_CODE: String = ""                 // 시도교육청코드
    var ATPT_OFCDC_SC_NM: String = ""
    var SD_SCHUL_CODE: String = ""                      // 행정표준코드
    var SCHUL_KND_SC_NM: String = ""                    // 학교종류명
    var LCTN_SC_NM: String = ""                         // 시도명
    var JU_ORG_NM: String = ""
    var FOND_YMD: String = ""
    var FOND_SC_NM: String = ""                         // 설립명
    var ORG_TELNO: String = ""                          // 전화번호
    var FOAS_MEMRD: String = ""
    var GRADE: String = ""                              // 반
    var ROLE: String = ""                               // parent or student
    var USER_UID: String = ""                           // Firebase uid
    var label: String = ""
    var register: Bool = true
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
    @Persisted dynamic var ORG_RDNMA: String = ""                       // 도로 주소
    @Persisted dynamic var ORG_RDNDA: String = ""                       // 도로 상세 주소
    @Persisted dynamic var ORG_TELNO: String = ""                       // 전화번호
    @Persisted dynamic var registerDate: Date = Date()
    
    static func < (lhs: SchoolInfoData, rhs: SchoolInfoData) -> Bool {
        return lhs.registerDate < rhs.registerDate
    }
}


struct AcademyInfo: Codable {
    var KEY: String = ""
    var ATPT_OFCDC_SC_CODE: String = ""                         // 시도교육청코드
    var ATPT_OFCDC_SC_NM: String = ""                           // 시도교육청명
    var ADMST_ZONE_NM: String = ""                              //  행정구역명
    var ACA_INSTI_SC_NM: String = ""                            // 학원교습소명
    var ACA_ASNUM: String = ""                                  // 학원지정번호
    var ACA_NM: String = ""                                     // 학원명
    var ESTBL_YMD: String = ""                                  // 개설일자
    var REG_YMD: String = ""                                    // 등록일자
    var REG_STTUS_NM: String = ""                               // 등록상태명
    var CAA_BEGIN_YMD: String = ""                              // 휴원시작일자
    var CAA_END_YMD: String = ""                                // 휴원종료일자
    var TOFOR_SMTOT: String = ""                                // 정원합계
    var DTM_RCPTN_ABLTY_NMPR_SMTOT: String = ""                 // 일시수용능력인원합계
    var REALM_SC_NM: String = ""                                // 분야명
    var LE_ORD_NM: String = ""                                  // 교습계열명
    var LE_CRSE_LIST_NM: String = ""                            // 교습과정목록명
    var LE_CRSE_NM: String = ""                                 // 교습과정명
    var PSNBY_THCC_CNTNT: String = ""                           // 인당수강료
    var THCC_OTHBC_YN: String = ""                              // 수강료공개여부
    var BRHS_ACA_YN: String = ""                                // 기숙사학원여부
    var FA_RDNMA: String = ""                                   // 도로명주소
    var FA_RDNDA: String = ""                                   // 도로명 주소
    var FA_RDNZC: String = ""                                   // 도로명우편번호
    var FA_TELNO: String = ""                                    // 전화번호
    var LOAD_DTM: String = ""                                    // 수정일자
    var label: String = ""
    var register: Bool = true
}
