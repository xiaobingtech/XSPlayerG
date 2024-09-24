//
//  XS_SiteSearchReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/22.
//

import Foundation
import ComposableArchitecture

@Reducer
struct XS_SiteSearchReducer {
    static func store(site: XS_SiteM) -> StoreOf<Self> {
        .init(initialState: .init(site: site)) { Self() }
    }
    @ObservableState
    struct State: Equatable {
        let site: XS_SiteM
        var search: XS_SDSiteSearch?
        var text: String = ""
        var current: String = ""
        var isLoading: Bool = false
        var list: [XS_VideoModel] = []
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case setList(String, [XS_VideoModel])
        case search
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .setList(text, list):
                if text == state.current {
                    state.list = list
                    state.isLoading = false
                }
                return .none
            case .search:
                if state.current == state.text { return .none }
                
                let text = state.text
                state.current = text
                state.list.removeAll()
                if text.isEmpty {
                    state.isLoading = false
                    return .none
                }
                
                if let search = state.search {
                    var arr = search.history
                    arr.removeAll { $0 == text }
                    arr.insert(text, at: 0)
                    search.history = Array(arr.prefix(10))
                }
                
                let site = state.site
                state.isLoading = true
                return .run { send in
                    do {
                        let data: [XS_VideoModel]
                        switch try await XS_NetWork.shared.search(site: site, wd: text) {
                        case let .list(list): data = list
                        case let .noMore(list): data = list
                        }
                        await send(.setList(text, data))
                    } catch {
                        debugPrint(error.localizedDescription)
                        await send(.setList(text, []))
                    }
                }
            }
        }
    }
}
