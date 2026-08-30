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
    
    func startListening(codeId: String, studentUid: String, onLinkCompleted: (([String]?) -> Void)? = nil) {
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
            let parentArray = data["parent"] as? [String] ?? []
            
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
}
