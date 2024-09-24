//
//  Item.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/12.
//

import Foundation
import SwiftData
import HandyJSON

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

//@Model
//final class XS_Item {
//    var tab: XS_FilmReducer.State.XS_TabType {
//        get { .init(rawValue: _tab) ?? .收藏 }
//        set { _tab = newValue.rawValue }
//    }
//    private var _tab: String
//    var collect: [XS_FilmReducer.State.XS_SaveItem] {
//        get { _collect.compactMap { .deserialize(from: $0) } }
//        set { _collect = newValue.compactMap { $0.toJSONString() } }
//    }
//    private var _collect: [String]
//    var history: [XS_FilmReducer.State.XS_SaveItem] {
//        get { _history.compactMap { .deserialize(from: $0) } }
//        set { _history = newValue.compactMap { $0.toJSONString() } }
//    }
//    private var _history: [String]
//    var searchSite: XS_SiteModel {
//        get { .deserialize(from: _searchSite) ?? .test_xml }
//        set { _searchSite = newValue.toJSONString() }
//    }
//    private var _searchSite: String?
//    var searchHistory: [String]
//    init(tab: String, collect:  [String], history:  [String], searchSite: String, searchHistory: [String]) {
//        self._tab = tab
//        self._collect = collect
//        self._history = history
//        self._searchSite = searchSite
//        self.searchHistory = searchHistory
//    }
//}

class XS_Item: XS_Model {
    var collect: [XS_FilmReducer.XS_SaveItem] = []
    var history: [XS_FilmReducer.XS_SaveItem] = []
    var search: [String] = []
}
