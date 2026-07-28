//
//  SignUpView.swift
//  KidsFullCare
//
//  Created by najak on 7/26/26.
//

import SwiftUI
import WebKit

struct SignUpView: UIViewRepresentable {
    @ObservedObject var userViewModel: UserViewModel
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // React → Swift 메시지 핸들러 등록
        userContentController.add(context.coordinator, name: "nativeBridge")
        // ------------------------------------------------------------------

        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        webView.scrollView.pinchGestureRecognizer?.delegate = context.coordinator
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.bouncesZoom = false
        webView.allowsLinkPreview = false
        
        webView.backgroundColor = .white
        userViewModel.webView = webView
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: userViewModel)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, UIGestureRecognizerDelegate {
        let userViewModel: UserViewModel
        var isInitialLoad: Bool = true
        
        init(viewModel: UserViewModel) {
            self.userViewModel = viewModel
        }
        
        func webView(
            _ webView: WKWebView,
            contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
            completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
        ) {
            completionHandler(nil) // nil 리턴 → 메뉴 자체가 뜨지 않음
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "nativeBridge" {
                
            }
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }

        // 💡 pinch gesture recognizer는 애초에 시작조차 못 하게 차단
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer is UIPinchGestureRecognizer {
                return false
            }
            return true
        }
    }
}
