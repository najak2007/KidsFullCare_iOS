//
//  MainView.swift
//  KidsFullCare
//
//  Created by najak on 7/28/26.
//

import SwiftUI

struct MainView: View {
    
    @State private var tabIndex: Int = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $tabIndex) {
                Tab("홈", systemImage: "house", value: 0) {
                    
                }
                
                Tab("알림", systemImage: "bell", value: 1) {
                    
                }
                
                Tab("설정", systemImage: "gearshape", value: 2) {
                    
                }
            }
        }
    }
}
