//
//  XS_IptvReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import Foundation
import ComposableArchitecture

@Reducer
struct XS_IptvReducer {
    static let store: StoreOf<XS_IptvReducer> = .init(initialState: .init()) { XS_IptvReducer() }
    @ObservableState
    struct State: Equatable {
        var url: String = ""
        var list: [XS_IptvGroupModel] = []
        var isLoading: Bool = false
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear(String)
        case setIptv(String)
        case setList(String, [XS_IptvGroupModel])
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .setList(iptv, list):
                if iptv == state.url {
                    state.list = list
                }
                return .none
            case let .setIptv(value):
                if value == state.url {
                    return .none
                }
                state.url = value
                state.list = []
                state.isLoading = true
                return loadList(url: value)
            case let .onAppear(value):
                guard state.list.isEmpty else {
                    return .none
                }
                state.url = value
                state.isLoading = true
                return loadList(url: value)
            }
        }
    }
    private func loadList(url: String) -> Effect<Action> {
        .run { send in
            do {
                let list = try await XS_NetWork.shared.iptvList(url)
                await send(.setList(url, list))
            } catch {
                debugPrint(error.localizedDescription)
            }
            await send(.binding(.set(\.isLoading, false)))
        }
    }
}
