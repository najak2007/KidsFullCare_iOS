//
//  ToastViewModifier.swift
//  TodayToDoList
//
//  Created by najak on 7/16/25.
//

import SwiftUI

struct ToastViewModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: toast?.position == .bottom ? -30 : toast?.position == .top ? 40 : 0)
                }.animation(.spring(), value: toast)
            )
            .onChange(of: toast) { oldValue, newValue in
                showToast()
            }
    }
    
    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            VStack {
                if toast.position == .bottom {
                    Spacer()
                    
                    ToastView(
                        type: toast.type,
                        title: toast.title,
                        message: toast.message) {
                            dismissToast()
                        }
                } else if toast.position == .top {
                    ToastView(
                        type: toast.type,
                        title: toast.title,
                        message: toast.message) {
                            dismissToast()
                        }
                    
                    Spacer()
                } else if toast.position == .center {
                    ToastView(
                        type: toast.type,
                        title: toast.title,
                        message: toast.message) {
                            dismissToast()
                        }
                }
            }
            .transition(.move(edge: toast.position == .bottom ? .bottom : toast.position == .top ? .top : .bottom))
        }
    }
    
    private func showToast() {
        guard let toast = toast else {
            return
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if toast.duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismissToast()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastViewModifier(toast: toast))
    }
}
