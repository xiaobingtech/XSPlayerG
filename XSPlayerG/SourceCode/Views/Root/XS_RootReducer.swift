//
//  XS_RootReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/12.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct XS_RootReducer {
    static let store: StoreOf<XS_RootReducer> = .init(initialState: .init()) { XS_RootReducer() }
    @ObservableState
    struct State: Equatable {
    }
    enum Action {
    }
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
//        case .request:
//            return .run { send in
//                let site = XS_SiteModel.test
//                await send(.setText("Loading"))
//                
//                let url = "https://tv.sohu.com/v/MjAyNDAxMjIvbjYwMTM3NjcyNS5zaHRtbA==.html"
//                let title = try await XS_NetWork.shared.getAnalysizeTitle(url: url)
//                await send(.setText(title))
//                
//                let hot = try await XS_NetWork.shared.baiduHot()
//                await send(.setText(hot.reduce("", { $0 + "\n" + $1.vod_name })))
                
//                let rr = try await XS_NetWork.shared.doubanRR(name: "繁花", year: "2023")
//                await send(.setText(rr.0 + "\n\n" + rr.1.joined(separator: "\n")))
                
//                let html = try await XS_NetWork.shared.doubanRate(name: "繁花", year: "2023")
//                await send(.setText(html))
                
//                let html = try await XS_NetWork.shared.doubanLink(name: "繁花", year: "2023")
//                await send(.setText(html))
                
//                let list = try await XS_NetWork.shared.list(site: site, t: "0")
//                await send(.setText(list.reduce("", { $0 + "\n" + $1.vod_name })))
                
//                let model = try await XS_NetWork.shared.classify(site: site)
//                await send(.setText(model.classData.reduce("", { $0 + "\n" + $1.type_name })))
//            }
    }
}
