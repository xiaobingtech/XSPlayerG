//
//  XS_AnalyzeReducer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/15.
//

import Foundation
import ComposableArchitecture

@Reducer
struct XS_AnalyzeReducer {
    static let store: StoreOf<XS_AnalyzeReducer> = .init(initialState: .init()) { XS_AnalyzeReducer() }
    @ObservableState
    struct State: Equatable {
//        var item: XS_IptvModel = .test_解析1
//        var all: [XS_IptvModel] = [.test_解析1, .test_解析25, .test_解析26, .test_解析27]
//        var url: String = ud_item.analyze
        var text: String = ""
        var title: String = "解析"
        var isAnalyze: Bool = false
        var action: _Action = .done
//        var list: [XS_SaveItem] = ud_item.analyzeList
        var listShow: Bool = false
    }
    enum Action: BindableAction {
        case binding(BindingAction<State>)
//        case setUrl(String)
//        case onGo
//        case onStar
//        case onList(XS_SaveItem)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
//            case .binding(\.list):
//                ud_save { $0.analyzeList = state.list }
//                return .none
            case .binding:
                return .none
//            case let .onList(value):
//                state.title = value.title
//                state.text = value.url
//                state.url = value.url
//                return .none
//            case .onStar:
//                var arr = state.list
//                if state.list.contains(where: { $0.url == state.text }) {
//                    arr.removeAll(where: { $0.url == state.text })
//                } else {
//                    let item = XS_SaveItem()
//                    item.title = state.title
//                    item.url = state.text
//                    arr.insert(item, at: 0)
//                }
//                state.list = arr
//                ud_save { $0.analyzeList = state.list }
//                return .none
//            case let .setUrl(value):
//                state.url = value
//                state.text = value
//                ud_save { $0.analyze = value }
//                return .none
//            case .onGo:
//                state.url = state.text
//                return .none
            }
        }
    }
    enum _Action {
        case done, goBack, goForward
    }
//    class XS_SaveItem: XS_Model, Equatable, Identifiable {
//        static func == (lhs: XS_SaveItem, rhs: XS_SaveItem) -> Bool {
//            lhs.id == rhs.id
//        }
//        var id: String { url }
//        var title: String = ""
//        var url: String = ""
//        
//        static var baidu: Self {
//            let model = Self()
//            model.title = "百度一下"
//            model.url = "https://www.baidu.com/"
//            return model
//        }
//        static var iqiyi: Self {
//            let model = Self()
//            model.title = "爱奇艺"
//            model.url = "https://m.iqiyi.com/"
//            return model
//        }
//        static var youku: Self {
//            let model = Self()
//            model.title = "优酷视频"
//            model.url = "https://youku.com/?screen=phone"
//            return model
//        }
//        static var qq: Self {
//            let model = Self()
//            model.title = "腾讯视频"
//            model.url = "https://m.v.qq.com/"
//            return model
//        }
//    }
}
