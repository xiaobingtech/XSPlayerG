//
//  XS_FilmReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/5.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import HandyJSON

//extension [XS_FilmReducer.XS_SaveItem] {
//    func contains(site: XS_SiteModel, model: XS_VideoModel) -> Bool {
//        contains { $0.equal(site: site, model: model) }
//    }
//}
//
//let ud_item: XS_Item = {
//    if let json = UserDefaults.standard.dictionary(forKey: "X"), let item = XS_Item.deserialize(from: json) {
//        return item
//    }
//    return .init()
//}()
//func ud_save(_ block: (XS_Item) -> Void) {
//    block(ud_item)
//    let json = ud_item.toJSON() ?? [:]
//    UserDefaults.standard.set(json, forKey: "X")
//    UserDefaults.standard.synchronize()
//}


struct XS_FilmReducer: Reducer {
    static let store: StoreOf<XS_FilmReducer> = .init(initialState: .init()) { XS_FilmReducer() }
    @ObservableState
    struct State: Equatable {
        var tab: XS_TabType = .历史
        enum XS_TabType: String {
            case 热门, 历史, 资源, 收藏
            static var all: [XS_TabType] { [.收藏, .历史, .热门, .资源] }
        }
        
        var hotList: [XS_VideoModel] = []
        var search: XS_SDSiteSearch!
        var enlightentHotType: XS_NetWork.XS_EnlightentHotType = .连续剧
        var hot_key: String = ""
    }
    enum Action: BindableAction {
        case upHot
        case binding(BindingAction<State>)
        case onAppear(XS_SDSiteSearch?)
        case setType(XS_NetWork.XS_EnlightentHotType)
        case setList(String, [XS_VideoModel])
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .setList(key, list):
                if key == state.hot_key {
                    state.hotList = list
                }
                return .none
            case let .setType(value):
                if value == state.enlightentHotType { return .none }
                state.hot_key = (state.search?.hot_key ?? "") + value.rawValue
                state.enlightentHotType = value
                state.hotList = []
                return loadList(search: state.search, type: state.enlightentHotType)
            case let .onAppear(value):
                state.search = value
                let key = (state.search?.hot_key ?? "") + state.enlightentHotType.rawValue
                if key == state.hot_key { return .none }
                state.hot_key = key
                state.hotList = []
                return loadList(search: state.search, type: state.enlightentHotType)
            case .upHot:
                state.hot_key = (state.search?.hot_key ?? "") + state.enlightentHotType.rawValue
                return loadList(search: state.search, type: state.enlightentHotType)
            }
        }
    }
    
    private func loadList(search: XS_SDSiteSearch?, type: XS_NetWork.XS_EnlightentHotType) -> Effect<Action> {
        guard let search = search else { return .none }
        let key = search.hot_key + type.rawValue
        return .run { send in
            let list: [XS_VideoModel]
            switch search.hot {
            case .豆瓣: list = try await XS_NetWork.shared.doubanHot()
            case .夸克: list = try await XS_NetWork.shared.quarkHot()
            case .百度: list = try await XS_NetWork.shared.baiduHot()
            case .酷云: list = try await XS_NetWork.shared.kyLiveHot()
            case .云合: list = try await XS_NetWork.shared.enlightentHot(channelType: type)
            case .none: list = try await XS_NetWork.shared.hot(site: search.toSite)
            }
            await send(.setList(key, list))
        }
    }
    
    class XS_SaveItem: XS_Model, Equatable, Identifiable {
        static func == (lhs: XS_FilmReducer.XS_SaveItem, rhs: XS_FilmReducer.XS_SaveItem) -> Bool {
            lhs.id == rhs.id
        }
        var id: String { site.id + model.vod_id + model.xs_remark }
        var site: XS_SiteModel!
        var model: XS_VideoModel!
        var selection: Int = 0
        var url: String = ""
        var sort: Bool = true
        var date: Date = Date()
        var url_name: Substring? { url.split(separator: "$").first }
        func equal(site: XS_SiteModel, model: XS_VideoModel) -> Bool {
            self.site.id == site.id && self.model.vod_id == model.vod_id
        }
        init(site: XS_SiteModel, model: XS_VideoModel, selection: Int = 0, url: String = "", sort: Bool = true, date: Date) {
            self.site = site
            self.model = model
            self.selection = selection
            self.url = url
            self.sort = sort
            self.date = date
        }
        required init() {
//            fatalError("init() has not been implemented")
        }
        override func mapping(mapper: HelpingMapper) {
            mapper <<<
                date <-- DateTransform()
        }
    }
}
