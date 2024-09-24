//
//  XS_NavReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/5.
//

import Foundation
import ComposableArchitecture
import SwiftUI

extension NavigationLink where Destination == Never {
    init(item: XS_NavReducer.State.XS_NavPathItem?, @ViewBuilder label: () -> Label) {
        self.init(value: item, label: label)
    }
}

@Reducer
struct XS_NavReducer {
    static let store: StoreOf<XS_NavReducer> = .init(initialState: .init()) { XS_NavReducer() }
    @ObservableState
    struct State: Equatable {
        var path: [XS_NavPathItem] = []
        enum XS_NavPathItem: Hashable {
            case detail(site: XS_SiteM, id: String, model: XS_VideoModel?)
            case site(site: XS_SiteM)
            case searchMore(site: XS_SiteM, text: String, models: [XS_VideoModel])
            case iptv(XS_IptvGroupModel)
            case setJx
            case setJxEdit(XS_SDAnalyze?)
            case setIptv
            case setIptvEdit(XS_SDIptv?)
            case setSearch
            case setSite(String)
            case setSiteGroup
            case setSiteEdit(XS_SDSite?)
            case setOther
            case siteChange(String)
            case setTest
        }
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
