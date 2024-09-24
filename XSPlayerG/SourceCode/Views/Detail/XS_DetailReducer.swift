//
//  XS_DetailReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/29.
//

import Foundation
import ComposableArchitecture

@Reducer
struct XS_DetailReducer {
    static var store: StoreOf<XS_DetailReducer> { .init(initialState: .init()) {XS_DetailReducer() } }
    
    @ObservableState
    struct State: Equatable {
        var site: XS_SiteM!
        var isError: Bool = false
        var model: XS_VideoModel?
        var score: String?
        var recommend: [XS_DoubanRecommendModel] = []
    }
    enum Action: BindableAction {
        case onAppear(XS_SiteM, String, XS_VideoModel?)
        case setDouban(String, [XS_DoubanRecommendModel])
        case binding(BindingAction<State>)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.model):
                if let model = state.model {
                    return .run { send in
                        do {
                            let (score, recommend) = try await XS_NetWork.shared.doubanRR(name: model.vod_name, year: model.vod_year)
                            await send(.setDouban(score, recommend))
                        } catch {
                            debugPrint(error.localizedDescription)
                        }
                    }
                } else {
                    return .none
                }
            case .binding:
                return .none
            case let .setDouban(score, recommend):
                state.score = score
                state.recommend = recommend
                return .none
            case let .onAppear(site, id, item):
                guard !state.isError, state.model == nil else { return .none }
                state.site = site
                return .run { send in
                    do {
                        let model = try await XS_NetWork.shared.detail(site: site, id: id).first
                        model?.isList = false
                        await send(.binding(.set(\.model, model ?? item)))
                    } catch {
                        debugPrint(error.localizedDescription)
                        await send(.binding(.set(\.isError, true)))
                        await send(.binding(.set(\.model, item)))
                    }
                }
            }
        }
    }
}
