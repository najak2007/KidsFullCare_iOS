//
//  MainView.swift
//  KidsFullCare
//
//  Created by najak on 7/28/26.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var authGate: AuthGateViewModel
    @State private var tabIndex: Int = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            TabView(selection: $tabIndex) {
                Tab("홈", systemImage: "house", value: 0) {
                    
                }
                
                Tab("알림", systemImage: "bell", value: 1) {
                    
                }
                
                Tab("설정", systemImage: "gearshape", value: 2) {
                    
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
