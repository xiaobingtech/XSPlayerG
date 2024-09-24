//
//  XS_SiteChangeReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/21.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct XS_SiteChangeReducer {
    static func store(text: String) -> StoreOf<Self> {
        .init(initialState: .init(text: text)) {
            Self()
        }
    }
    @ObservableState
    struct State: Equatable {
        let text: String
        var loading: String = ""
        var lists: [String:[XS_VideoModel]] = [:]
        var sites: [XS_SDSite] = []
    }
    enum Action {
        case loadMore([XS_SDSite])
        case setList(XS_SDSite, [XS_VideoModel])
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .setList(site, list):
            state.lists[site.api] = list
            state.loading = state.lists.count == state.sites.count ? "" : "\(state.lists.count)/\(state.sites.count)"
            return .none
        case let .loadMore(value):
            guard state.loading.isEmpty else { return .none }
            if state.sites.isEmpty {
                state.sites = value
            }
            state.lists.removeAll()
            let sites = state.sites
            let wd = state.text
            state.loading = "0/\(sites.count)"
            return .run { send in
                for site in sites {
                    do {
                        let data: [XS_VideoModel]
                        switch try await XS_NetWork.shared.search(site: site.toSite, wd: wd) {
                        case let .list(list): data = list
                        case let .noMore(list): data = list
                        }
                        await send(.setList(site, data))
                    } catch {
                        debugPrint(error.localizedDescription)
                        await send(.setList(site, []))
                    }
                }
            }
        }
    }
}
