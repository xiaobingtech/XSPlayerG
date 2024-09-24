//
//  XS_SettingReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/18.
//

import Foundation
import ComposableArchitecture

@Reducer
struct XS_SettingReducer {
    static let store: StoreOf<XS_SettingReducer> = .init(initialState: .init()) { XS_SettingReducer() }
    @ObservableState
    struct State: Equatable {
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
}
