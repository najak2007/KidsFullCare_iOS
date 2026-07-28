//
//  ContentView.swift
//  KidsFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var isAuthState: Bool = false

    init() {
        isAuthState = Auth.auth().currentUser != nil
    }
    
    var body: some View {
        ZStack {
            Color("1F2020")
                .ignoresSafeArea()
            
            
            if isAuthState {
                
            } else {
                if let url = URL(string: Config.KIDS_FULL_CARE_URL) {
                    SignUpView(userViewModel: userViewModel, url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
