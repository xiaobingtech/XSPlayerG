//
//  XS_SearchReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/8.
//

import Foundation
import ComposableArchitecture
import SwiftUI

extension ViewStore where ViewState == XS_SDSite, ViewAction == XS_SearchReducer.Action {
    var binding: Binding<ViewState> {
        binding(send: ViewAction.setSite)
    }
}

@Reducer
struct XS_SearchReducer {
    static let store: StoreOf<XS_SearchReducer> = .init(initialState: .init()) { XS_SearchReducer() } 
    @ObservableState
    struct State: Equatable {
        var text: String = ""
        
        var lists: [String:[XS_VideoModel]] = [:]
        var loading: String = ""
        
        var current: [XS_SDSite] = []
        
        var search: XS_SDSiteSearch!
        var all: [XS_SDSite] = [.all]
        var site: XS_SDSite = .all
    }
    enum Action: BindableAction {
        case onAppear(XS_SDSiteSearch?, [XS_SDSite])
        case setSite(XS_SDSite)
        case search(String)
        case setList(String, XS_SDSite, [XS_VideoModel])
        case clearHistory
        case binding(BindingAction<State>)
    }
    var body: some Reducer<State, Action> {
        @AppStorage("XS_SearchModifier.Site") var api: String = ""
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .onAppear(search, sites):
                state.search = search
                state.all = [.all] + sites
                state.site = sites.first { $0.api == api } ?? .all
                return .none
            case .clearHistory:
                state.search.history.removeAll()
                return .none
            case let .setSite(value):
                if value != state.site {
                    api = value.api
                    state.site = value
                    state.text = ""
                    state.loading = ""
                }
                return .none
            case let .setList(text, site, list):
                if text == state.text {
                    state.lists[site.api] = list
                    state.loading = state.lists.count == state.current.count ? "" : "\(state.lists.count)/\(state.current.count)"
                }
                return .none
            case let .search(value):
                if value == state.text {
                    return .none
                }
                state.text = value
                state.lists.removeAll()
                if value.isEmpty {
                    state.loading = ""
                    return .none
                }
                
                var arr = state.search.history
                arr.removeAll { $0 == value }
                arr.insert(value, at: 0)
                state.search.history = Array(arr.prefix(10))
                
                let sites: [XS_SDSite]
                if state.site.api.isEmpty {
                    var all = state.all
                    all.removeFirst()
                    sites = all
                } else {
                    sites = [state.site]
                }
                state.current = sites
                state.loading = "0/\(sites.count)"
                return .run { send in
                    for site in sites {
                        do {
                            let data: [XS_VideoModel]
                            switch try await XS_NetWork.shared.search(site: site.toSite, wd: value) {
                            case let .list(list): data = list
                            case let .noMore(list): data = list
                            }
                            await send(.setList(value, site, data))
                        } catch {
                            debugPrint(error.localizedDescription)
                            await send(.setList(value, site, []))
                        }
                    }
                }
            }
        }
    }
}
