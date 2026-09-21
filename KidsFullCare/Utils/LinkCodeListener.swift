//
//  LinkCodeListener.swift
//  KidsFullCare
//
//  Created by najak on 8/30/26.
//

import FirebaseFirestore

class LinkCodeListener {
    
    static let shared = LinkCodeListener()
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var previousUsed: Bool?
    private var previousParentCount: Int = 0
    
    func startListening(codeId: String, studentUid: String, onLinkCompleted: (([[String: Any]]?) -> Void)? = nil) {
        let documentRef = db.collection("linkCodes").document(codeId)
        
        listener = documentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self,
                  let snapshot = documentSnapshot,
                  snapshot.exists,
                  let data = snapshot.data()
            else {
#if DEBUG
                print("문서를 불러오는데 실패했습니다. \(error?.localizedDescription ?? "")")
#endif
                onLinkCompleted?(nil)
                return
            }
            
            guard let currentStudentUid = data["studentUid"] as? String,
                  currentStudentUid == studentUid
            else {
                onLinkCompleted?(nil)
                return
            }
            
            let currentUsed = data["used"] as? Bool ?? false
            let parentArray = data["parent"] as? [[String: Any]] ?? []
            
            if let prevUsed = self.previousUsed {
                let isUsedChanged = (prevUsed == false && currentUsed == true)
                let isParentUpdated = !parentArray.isEmpty
                
                if isUsedChanged && isParentUpdated {
                    DispatchQueue.main.async {
#if DEBUG
                        print(" [신호 수신] 학부모 연결 완료!")
#endif
                        onLinkCompleted?(parentArray)
                    }
                }
            }
            
            self.previousUsed = currentUsed
            self.previousParentCount = parentArray.count
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    func removelinkCodes(userUid: String, codeId: String) {
        db.collection("linkCodes").document(codeId).getDocument { snapshot, error in
            if error == nil {
                guard let document = snapshot,
                        document.exists,
                      let data = document.data(),
                      let uid = data["studentUid"] as? String,
                        userUid == uid,
                      let used = data["used"] as? Bool,
                      let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                else {
                    return
                }
                
                if (used == true) || Date.isExpired(date: createdAt, timeInterval: Config.QRCODE_AUTH_TIME) {
                    self.db.collection("linkCodes").document(codeId).delete { error in
                        if let error = error {
#if DEBUG
                            print("문서 삭제 실패 : \(error.localizedDescription)")
#endif
                        } else {
#if DEBUG
                            print("문서가 성공적으로 삭제되었습니다.")
#endif
                        }
                    }
                }
            }
        }
    }
    
    func allDeleteExpiredLinkCode(userUid: String, completion: @escaping() -> Void) {
        let cutoffDate = Date().addingTimeInterval(-Config.QRCODE_AUTH_TIME)
        let cutooffTimestamp = Timestamp(date: cutoffDate)
        
        db.collection("linkCodes")
            .whereField("studentUid", isEqualTo: userUid)
            .whereField("createdAt", isLessThan: cutooffTimestamp)
            .getDocuments { snapshot, error in
                if let error = error {
#if DEBUG
                    print("만료 코드 조회 실패: \(error)")
#endif
                    completion()
                    return
                }
                guard let documents = snapshot?.documents,
                        !documents.isEmpty
                else {
                    completion()
                    return
                }
                
                let batch = Firestore.firestore().batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
#if DEBUG
                        print("일괄 삭제 실패: \(error)")
#endif
                        completion()
                    } else {
#if DEBUG
                        print("만료된 코드 \(documents.count)개 삭제 완료")
#endif
                        completion()
                    }
                }
            }
    }
}
