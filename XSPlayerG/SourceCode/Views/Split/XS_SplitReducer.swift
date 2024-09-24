//
//  XS_SplitReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/5.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct XS_SplitReducer {
    static let store: StoreOf<XS_SplitReducer> = .init(initialState: .init()) { XS_SplitReducer() }
    @ObservableState
    struct State: Equatable {
        var type: XS_SplitType = .影视
        var show: Bool = false
        enum XS_SplitType: String, Identifiable {
            var id: Self { self }
            case 影视, 电视, 解析, 设置
            static var all: [Self] { [.影视, .电视, .解析, .设置] }
        }
    }
    enum Action {
        case setType(State.XS_SplitType)
        case setShow(Bool)
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .setShow(value):
            state.show = value
            return .none
        case let .setType(value):
            state.show = false
            state.type = value
            return .none
        }
    }
}
