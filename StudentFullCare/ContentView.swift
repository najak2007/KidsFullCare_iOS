//
//  ContentView.swift
//  StudentFullCare
//
//  Created by najak on 7/18/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    var body: some View {
        VStack {
#if true
            IntroView()
#else
            LoginView()
#endif
        }
        .padding()
    }
}
