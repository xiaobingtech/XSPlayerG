//
//  XS_SearchMoreReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/9.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct XS_SearchMoreReducer {
    static func store(site: XS_SiteM, text: String, models: [XS_VideoModel]) -> StoreOf<XS_SearchMoreReducer> {
//        var loading: XS_LoadingModel = .init()
//        if models.count > 3, models.count < 10 {
//            loading.set(.noMore)
//        }
//        return .init(initialState: .init(site: site, text: text, list: models, page: models.isEmpty ? 0 : 1, loading: loading)) {
//            XS_SearchMoreReducer()
//        }
        .init(initialState: .init(site: site, text: text, list: models, page: models.isEmpty ? 0 : 1, loading: .init())) {
            XS_SearchMoreReducer()
        }
    }
    @ObservableState
    struct State: Equatable {
        let site: XS_SiteM
        let text: String
        var list: [XS_VideoModel]
        var page: Int
        var loading: XS_LoadingModel
    }
    enum Action {
        case loadMore
        case loading(XS_LoadingModel.XS_Status)
        case insertList([XS_VideoModel], Int)
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .insertList(value, pg):
            state.list += value
            state.page = pg
            return .none
        case let .loading(value):
            state.loading.set(value)
            return .none
        case .loadMore:
            guard state.loading.status == .idle else { return .none }
            let pg = state.page + 1
            let text = state.text
            let site = state.site
            return .run { send in
                await send(.loading(.loading))
                do {
                    switch try await XS_NetWork.shared.search(site: site, wd: text, pg: pg) {
                    case let .list(list):
                        await send(.insertList(list, pg))
                        await send(.loading(.idle))
                    case let .noMore(list):
                        await send(.insertList(list, pg))
                        await send(.loading(.noMore))
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                    await send(.loading(.idle))
                }
            }
        }
    }
}
