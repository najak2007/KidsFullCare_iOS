//
//  ToastModel.swift
//  TodayToDoList
//
//  Created by najak on 7/16/25.
//

import SwiftUI

enum ToastPosition {
    case top
    case center
    case bottom
}

struct Toast: Equatable {
    var type: ToastStyle
    var title: String
    var message: String
    var duration: Double = 5
    var position: ToastPosition = .bottom
}
