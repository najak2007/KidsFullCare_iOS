//
//  LinkedStudentsInfoViewModel.swift
//  KidsFullCare
//
//  Created by najak on 9/27/26.
//

import FirebaseFirestore
import Combine


@MainActor
final class LinkedStudentsInfoViewModel: ObservableObject {
    @Published var schoolInfoByStudent: [String: SchoolInfo] = [:]
    @Published var newlyRegisteredStudentUid: String? // 신규 등록 알림용

    private var listeners: [ListenerRegistration] = []
    private let db = Firestore.firestore()

    func start(forParentUid parentUid: String) {
        stop() // 기존 리스너 정리 후 재시작

        db.collection("users").document(parentUid)
            .getDocument { [weak self] snapshot, error in
                guard let self else { return }
                guard let data = snapshot?.data(),
                      let familyRaw = data["family"] as? [[String: Any]] else { return }

                let family = familyRaw.compactMap { dict -> FamilyMember? in
                    guard let name = dict["name"] as? String,
                          let uid = dict["uid"] as? String else { return nil }
                    return FamilyMember(name: name, uid: uid)
                }

                for member in family {
                    self.attachListener(studentUid: member.uid)
                }
            }
    }

    private func attachListener(studentUid: String) {
        let ref = db.collection("users").document(studentUid)
            .collection("meta").document("school")

        let listener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            guard let snapshot else { return }

            let existedBefore = self.schoolInfoByStudent[studentUid] != nil

            guard snapshot.exists,
                  let info = try? snapshot.data(as: SchoolInfo.self) else {
                self.schoolInfoByStudent[studentUid] = nil
                return
            }

            self.schoolInfoByStudent[studentUid] = info

            // 최초 등록(문서가 없다가 생김) 감지
            if !existedBefore {
                self.newlyRegisteredStudentUid = studentUid
            }
        }

        listeners.append(listener)
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }
}
