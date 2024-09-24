//
//  XS_LoadingView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/27.
//

import SwiftUI

struct XS_LoadingView: View {
    let item: XS_LoadingModel
    var body: some View {
        Group {
            switch item.status {
            case .idle, .refresh, .loading:
                ProgressView()
            case .noMore:
                Text("—— 没有更多内容 ——")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct XS_LoadingModel: Equatable {
    enum XS_Status: Equatable {
        case idle, loading, noMore, refresh
    }
    var status: XS_Status {
        let values = all.values
        if values.contains(.loading) {
            return .loading
        }
        if values.contains(.noMore) {
            return .noMore
        }
        return .idle
    }
    private var all: [String : XS_Status] = [:]
    mutating func set(_ state: XS_Status?, key: String = "default") {
        all[key] = state
    }
}
