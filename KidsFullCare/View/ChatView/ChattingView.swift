//
//  ChatingView.swift
//  KidsFullCare
//
//  Created by najak on 9/6/26.
//

import Foundation
import SwiftUI
import Combine

struct ChattingView: View {
    @StateObject private var viewModel = ChatMessageViewModel()
    @State private var inputText: String = ""
    @State private var userInfo: [UserInfo] = []
    
    @Namespace private var bottomID
    
    init(userInfo: UserInfo) {
        _userInfo = State(initialValue: [userInfo])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, userInfo: userInfo)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                .background(Color(.systemGroupedBackground))
                .onChange(of: viewModel.messages) { oldValue, newValue in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            
            Divider()
            
            ChatInputBar(text: $inputText) {
                viewModel.send(inputText)
                inputText = ""
            }
        }
        .navigationTitle(chattingForTitle())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func chattingForTitle() -> String {
        if !userInfo.isEmpty {
            if let userName = userInfo.first?.userName, !userName.isEmpty {
                return "\(userName) 님에게 알림 보내기"
            }
        }
        return "알림 보내기"
    }
}
  
// MARK: - Message Row (좌/우 정렬 + 프로필)
struct MessageRow: View {
    let message: ChatMessage
    let userInfo: [UserInfo]
  
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMine {
                Spacer(minLength: 40)
                    timestamp
                    bubble
            } else {
                profileImage
                bubble
                timestamp
                Spacer(minLength: 40)
            }
         }
     }
  
    private var profileImage: some View {
        // 1. 배열 전체 순회 대신 first(where:) 사용
        // 2. Base64 접두사(data:image/...) 제거 로직 포함 (필요 시)
        Group {
            if let user = userInfo.first(where: { $0.userId == message.userUid }),
               let profieImage = user.profieImage {
                Image(uiImage: profieImage)
                        .resizable()
                        .scaledToFill()
            } else {
                placeholderProfile
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
     }
  
     private var placeholderProfile: some View {
         Circle()
             .fill(Color(.systemGray4))
             .overlay(
                 Image(systemName: "person.fill")
                     .foregroundColor(.white)
                     .font(.system(size: 16))
             )
     }
  
     private var bubble: some View {
         Text(message.text)
             .font(.system(size: 15))
             .foregroundColor(.black)
             .padding(.horizontal, 12)
             .padding(.vertical, 9)
             .background(
                 BubbleShape(isMine: message.isMine)
                     .fill(message.isMine ? Color(red: 1.0, green: 0.90, blue: 0.30) : Color.white)
             )
             .frame(maxWidth: 260, alignment: message.isMine ? .trailing : .leading)
     }
  
     private var timestamp: some View {
         Text(message.date, style: .time)
             .font(.system(size: 10))
             .foregroundColor(.gray)
     }
}
  
// MARK: - Bubble Shape (꼬리 달린 말풍선)
  
struct BubbleShape: Shape {
     let isMine: Bool
     var cornerRadius: CGFloat = 16
     var tailSize: CGFloat = 7
  
     func path(in rect: CGRect) -> Path {
         var path = Path()
  
         let tl = CGPoint(x: rect.minX, y: rect.minY)
         let tr = CGPoint(x: rect.maxX, y: rect.minY)
         let bl = CGPoint(x: rect.minX, y: rect.maxY)
         let br = CGPoint(x: rect.maxX, y: rect.maxY)
  
         if isMine {
             // 오른쪽 아래에 꼬리 (내가 보낸 메시지)
             path.move(to: CGPoint(x: tl.x + cornerRadius, y: tl.y))
             path.addLine(to: CGPoint(x: tr.x - cornerRadius, y: tr.y))
             path.addArc(center: CGPoint(x: tr.x - cornerRadius, y: tr.y + cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
             path.addLine(to: CGPoint(x: br.x, y: br.y - cornerRadius - tailSize))
             // 꼬리 삼각형
             path.addLine(to: CGPoint(x: br.x + tailSize, y: br.y - cornerRadius * 0.2))
             path.addLine(to: CGPoint(x: br.x - cornerRadius * 0.6, y: br.y))
             path.addLine(to: CGPoint(x: bl.x + cornerRadius, y: bl.y))
             path.addArc(center: CGPoint(x: bl.x + cornerRadius, y: bl.y - cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
             path.addLine(to: CGPoint(x: tl.x, y: tl.y + cornerRadius))
             path.addArc(center: CGPoint(x: tl.x + cornerRadius, y: tl.y + cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
         } else {
             // 왼쪽 아래에 꼬리 (상대가 보낸 메시지)
             path.move(to: CGPoint(x: tl.x + cornerRadius, y: tl.y))
             path.addLine(to: CGPoint(x: tr.x - cornerRadius, y: tr.y))
             path.addArc(center: CGPoint(x: tr.x - cornerRadius, y: tr.y + cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
             path.addLine(to: CGPoint(x: tr.x, y: br.y - cornerRadius))
             path.addArc(center: CGPoint(x: tr.x - cornerRadius, y: br.y - cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
             path.addLine(to: CGPoint(x: bl.x + cornerRadius * 0.6, y: br.y))
             // 꼬리 삼각형
             path.addLine(to: CGPoint(x: bl.x - tailSize, y: bl.y - cornerRadius * 0.2))
             path.addLine(to: CGPoint(x: bl.x, y: bl.y - cornerRadius - tailSize))
             path.addLine(to: CGPoint(x: tl.x, y: tl.y + cornerRadius))
             path.addArc(center: CGPoint(x: tl.x + cornerRadius, y: tl.y + cornerRadius),
                         radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
         }
  
         path.closeSubpath()
         return path
     }
}
  
// MARK: - Input Bar (빈 상태 1줄 → 최대 3줄까지 가변 높이 → 스크롤)
 
struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
 
    // 1줄 기준 높이와 최대 3줄 높이를 계산하기 위한 값
    private let lineHeight: CGFloat = 20
    private let verticalPadding: CGFloat = 16 // 상하 패딩 합
    private let maxLines: Int = 3
 
    private var minHeight: CGFloat { lineHeight + verticalPadding }
    private var maxHeight: CGFloat { CGFloat(maxLines) * lineHeight + verticalPadding }
 
    // ExpandingTextView가 실측한 실제 컨텐츠 높이 (min~max 사이로 clamp된 값)
    @State private var textViewHeight: CGFloat = 36
 
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button(action: {}) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .frame(width: 28, height: 28)
            }
 
            ExpandingTextView(
                text: $text,
                height: $textViewHeight,
                minHeight: minHeight,
                maxHeight: maxHeight
            )
            .frame(height: textViewHeight) // 실측 높이로 고정 (빈 상태=1줄, 입력 증가 시 최대 3줄까지 증가)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemGray6))
            )
 
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.4) : .yellow)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .onAppear {
            textViewHeight = minHeight
        }
    }
}
 
// MARK: - UITextView 기반 가변 높이(빈 상태 1줄 → 최대 3줄 → 스크롤) 텍스트 입력
 
struct ExpandingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let minHeight: CGFloat
    let maxHeight: CGFloat
 
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }
 
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        recalculateHeight(uiView)
    }
 
    /// 실제 컨텐츠 높이를 측정해서 min~max 사이로 clamp한 뒤 height 바인딩에 반영.
    /// 최대 높이를 넘으면 그때부터 내부 스크롤을 켠다.
    private func recalculateHeight(_ uiView: UITextView) {
        let width = uiView.bounds.width > 0 ? uiView.bounds.width : UIScreen.main.bounds.width
        let fittingSize = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
 
        let clampedHeight = min(max(fittingSize.height, minHeight), maxHeight)
        uiView.isScrollEnabled = fittingSize.height > maxHeight
 
        if abs(height - clampedHeight) > 0.5 {
            DispatchQueue.main.async {
                height = clampedHeight
            }
        }
    }
 
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
 
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ExpandingTextView
 
        init(_ parent: ExpandingTextView) {
            self.parent = parent
        }
 
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.recalculateHeight(textView)
        }
    }
}
 
