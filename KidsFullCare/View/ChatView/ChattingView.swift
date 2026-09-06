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
    @Namespace private var bottomID
    
    var body: some View {
         VStack(spacing: 0) {
             ScrollViewReader { proxy in
                 ScrollView {
                     LazyVStack(alignment: .leading, spacing: 12) {
                         ForEach(viewModel.messages) { message in
                             MessageRow(message: message)
                         }
                         Color.clear
                             .frame(height: 1)
                             .id(bottomID)
                     }
                     .padding(.horizontal, 12)
                     .padding(.top, 12)
                 }
                 .background(Color(.systemGroupedBackground))
                 .onChange(of: viewModel.messages) { _ in
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
         .navigationTitle("채팅방")
         .navigationBarTitleDisplayMode(.inline)
     }
 }
  
 // MARK: - Message Row (좌/우 정렬 + 프로필)
  
 struct MessageRow: View {
     let message: ChatMessage
  
     var body: some View {
         HStack(alignment: .bottom, spacing: 8) {
             if message.isMine {
                 Spacer(minLength: 40)
                 timestamp
                 bubble
             } else {
//                 profileImage
                 bubble
                 timestamp
                 Spacer(minLength: 40)
             }
         }
     }
  
//     private var profileImage: some View {
//         AsyncImage(url: message.profileImageURL) { phase in
//             switch phase {
//             case .success(let image):
//                 image
//                     .resizable()
//                     .scaledToFill()
//             case .failure:
//                 placeholderProfile
//             case .empty:
//                 placeholderProfile
//                     .overlay(
//                         ProgressView()
//                             .scaleEffect(0.6)
//                     )
//             @unknown default:
//                 placeholderProfile
//             }
//         }
//         .frame(width: 36, height: 36)
//         .clipShape(Circle())
//     }
  
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
  
 // MARK: - Input Bar (최대 3줄까지 가변 높이)
  
 struct ChatInputBar: View {
     @Binding var text: String
     var onSend: () -> Void
  
     // 1줄 기준 높이와 최대 3줄 높이를 계산하기 위한 값
     private let lineHeight: CGFloat = 20
     private let verticalPadding: CGFloat = 16 // 상하 패딩 합
     private let maxLines: Int = 3
  
     private var textHeight: CGFloat {
         let lineCount = max(1, min(maxLines, currentLineCount))
         return CGFloat(lineCount) * lineHeight
     }
  
     private var currentLineCount: Int {
         // 개행 기준 + 대략적인 줄바꿈 추정 (완전 정확하진 않지만 3줄 제한 목적엔 충분)
         let newlineCount = text.components(separatedBy: "\n").count
         return newlineCount
     }
  
     var body: some View {
         HStack(alignment: .bottom, spacing: 8) {
             Button(action: {}) {
                 Image(systemName: "plus")
                     .foregroundColor(.gray)
                     .frame(width: 28, height: 28)
             }
  
             ExpandingTextView(
                 text: $text,
                 maxLines: maxLines,
                 lineHeight: lineHeight
             )
             .frame(minHeight: lineHeight + verticalPadding, maxHeight: CGFloat(maxLines) * lineHeight + verticalPadding)
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
     }
 }
  
 // MARK: - UITextView 기반 가변 높이(최대 3줄) 텍스트 입력
  
 struct ExpandingTextView: UIViewRepresentable {
     @Binding var text: String
     let maxLines: Int
     let lineHeight: CGFloat
  
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
         // 최대 라인 수를 초과하면 스크롤 활성화, 그 이하면 스크롤 비활성화(자동 높이 증가)
         let estimatedLines = uiView.contentSize.height / lineHeight
         uiView.isScrollEnabled = estimatedLines > CGFloat(maxLines)
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
         }
     }
}
  
