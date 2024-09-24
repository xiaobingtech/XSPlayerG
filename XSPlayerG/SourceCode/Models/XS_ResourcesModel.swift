//
//  XS_ResourcesModel.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/18.
//

import Foundation
import SwiftData

class XS_ResourcesModel: XS_Model {
    var analyze: [_Analyze] = []
    class _Analyze: XS_Model {
        var name: String = ""
        var url: String = ""
    }
    var iptv: [_Iptv] = []
    class _Iptv: XS_Model {
        var name: String = ""
        var url: String = ""
        var epg: String = ""
    }
    var sites: [_Site] = []
    class _Site: XS_Model {
        var key: String = ""
        var name: String = ""
        var api: String = ""
        var download: String = ""
        var jiexiUrl: String = ""
        var playUrl: String = ""
        var group: String = ""
        var type: Int = 0
    }
    
    static var rescources: XS_ResourcesModel? {
        do {
            guard let path = Bundle.main.path(forResource: "Resources", ofType: "json") else {
                throw XS_Error.invalidData
            }
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? NSDictionary else {
                throw XS_Error.invalidData
            }
            return XS_ResourcesModel.deserialize(from: dict)
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}
@Model
final class XS_SDAnalyze: Hashable {
    var name: String
    var url: String
    var sort: Int
    var isActive: Bool = true
    var test: Bool?
    init(name: String, url: String, sort: Int) {
        self.name = name
        self.url = url
        self.sort = sort
    }
}
@Model
final class XS_SDAnalyzeCollect: Hashable {
    var name: String
    var url: String
    var sort: Int
    init(name: String, url: String, sort: Int) {
        self.name = name
        self.url = url
        self.sort = sort
    }
    static var list: [XS_SDAnalyzeCollect] {
        [
            XS_SDAnalyzeCollect(name: "百度一下", url: "https://www.baidu.com/", sort: 0),
            XS_SDAnalyzeCollect(name: "爱奇艺", url: "https://m.iqiyi.com/", sort: 1),
            XS_SDAnalyzeCollect(name: "优酷视频", url: "https://youku.com/?screen=phone", sort: 2),
            XS_SDAnalyzeCollect(name: "腾讯视频", url: "https://m.v.qq.com/", sort: 3)
        ]
    }
}
@Model
final class XS_SDIptv: Hashable {
    var name: String
    var url: String
    var epg: String
    var sort: Int
    var isActive: Bool = true
    var test: Bool?
    init(name: String, url: String, epg: String, sort: Int) {
        self.name = name
        self.url = url
        self.epg = epg
        self.sort = sort
    }
}
@Model
final class XS_SDChannel: Hashable {
    var name: String
    var url: String
    var sort: Int
    init(name: String, url: String, sort: Int) {
        self.name = name
        self.url = url
        self.sort = sort
    }
}
@Model
final class XS_SDSiteSearch: Hashable {
    @Relationship(inverse: \XS_SDSite.search)
    var sites: [XS_SDSite] = []
    var history: [String] = []
    var is18: Bool = true
    
    var hot: _HotType? = _HotType.豆瓣
    var hot_name: String = ""
    var hot_api: String = ""
    var hot_type: XS_SDSite._Type?
    init() {}
}
extension XS_SDSiteSearch {
    enum _HotType: String, CaseIterable, Codable {
        case 豆瓣, 夸克, 百度, 酷云, 云合
    }
    var toSite: XS_SiteM {
        .init(name: hot_name, api: hot_api, playUrl: "", type: hot_type)
    }
    var hot_title: String {
        if let hot = hot {
            return hot.rawValue
        } else {
            return hot_name
        }
    }
    var hot_key: String {
        if let hot = hot {
            return hot.rawValue
        } else {
            return hot_api
        }
    }
}
@Model
final class XS_SDSiteGroup: Hashable {
    var name: String
    var sort: Int
    var isActive: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \XS_SDSite.group)
    var sites: [XS_SDSite] = []
    init(name: String, sort: Int) {
        self.name = name
        self.sort = sort
    }
}
@Model
final class XS_SDSite: Hashable {
    var name: String
    var api: String
    var download: String
    var playUrl: String
    var type: _Type?
    var sort: Int
    var sort_search: Int = 0
    var isActive: Bool = true
    var test: Bool?
    var group: XS_SDSiteGroup!
    var search: XS_SDSiteSearch?
    init(name: String, api: String, download: String, playUrl: String, type: _Type?, sort: Int) {
        self.name = name
        self.api = api
        self.download = download
        self.playUrl = playUrl
        self.type = type
        self.sort = sort
    }
}
extension XS_SDSite {
    enum _Type: Int, CaseIterable, Codable {
        case cms_xml = 0
        case cms_json
        case drpy_js0
        case app_v3
        case app_v1
        var name: String {
            switch self {
            case .cms_xml: return "xml"
            case .cms_json: return "json"
            case .drpy_js0: return "drpy"
            case .app_v3: return "app[v3]"
            case .app_v1: return "app[v1]"
            }
        }
    }
    var toSite: XS_SiteM {
        .init(name: name, api: api, playUrl: playUrl, type: type)
    }
    static var all: Self {
        Self.init(name: "全部", api: "", download: "", playUrl: "", type: nil, sort: 0)
    }
}
extension XS_SiteModel {
    var toSite: XS_SiteM {
        .init(name: name, api: api, playUrl: playUrl.isEmpty ? jiexiUrl : playUrl, type: type == nil ? nil : .init(rawValue: type!.rawValue))
    }
}

@Model
final class XS_SDSiteCollect: Hashable {
    var name: String
    var api: String
    var playUrl: String
    var type: XS_SDSite._Type?
    
    var vod_id: String
    var vod_name: String
    var vod_remark: String
    var vod_pic: String
    var vod_type: String
    
    var sort: Int
        
    init(name: String, api: String, playUrl: String, type: XS_SDSite._Type?, vod_id: String, vod_name: String, vod_remark: String, vod_pic: String, vod_type: String, sort: Int) {
        self.name = name
        self.api = api
        self.playUrl = playUrl
        self.type = type
        self.vod_id = vod_id
        self.vod_name = vod_name
        self.vod_remark = vod_remark
        self.vod_pic = vod_pic
        self.vod_type = vod_type
        self.sort = sort
    }
    init(site: XS_SiteM, model: XS_VideoModel, sort: Int) {
        self.name = site.name
        self.api = site.api
        self.playUrl = site.playUrl
        self.type = site.type
        self.vod_id = model.vod_id
        self.vod_name = model.vod_name
        self.vod_remark = model.xs_remark
        self.vod_pic = model.vod_pic
        self.vod_type = model.type_name
        self.sort = sort
    }
}
extension XS_SDSiteCollect {
    var toSite: XS_SiteM {
        .init(name: name, api: api, playUrl: playUrl, type: type)
    }
}

@Model
final class XS_SDSiteHistory: Hashable {
    var name: String
    var api: String
    var playUrl: String
    var type: XS_SDSite._Type?
    
    var vod_id: String
    var vod_name: String
    var vod_type: String
    
    var sort: Bool
    var selection: Int
    var url: String
    var date: Date
    
    init(name: String, api: String, playUrl: String, type: XS_SDSite._Type?, vod_id: String, vod_name: String, vod_type: String, sort: Bool, selection: Int = 0, url: String, date: Date = Date()) {
        self.name = name
        self.api = api
        self.playUrl = playUrl
        self.type = type
        self.vod_id = vod_id
        self.vod_name = vod_name
        self.vod_type = vod_type
        self.sort = sort
        self.selection = selection
        self.url = url
        self.date = date
    }
    init(site: XS_SiteM, model: XS_VideoModel, sort: Bool, selection: Int = 0, url: String, date: Date = Date()) {
        self.name = site.name
        self.api = site.api
        self.playUrl = site.playUrl
        self.type = site.type
        self.vod_id = model.vod_id
        self.vod_name = model.vod_name
        self.vod_type = model.type_name
        self.sort = sort
        self.selection = selection
        self.url = url
        self.date = date
    }
}
extension XS_SDSiteHistory {
    var toSite: XS_SiteM {
        .init(name: name, api: api, playUrl: playUrl, type: type)
    }
    var url_name: Substring? { url.split(separator: "$").first }
}
/*
{
    "analyze": [
        {
            "name": "解析1",
            "url": "https://jx.777jiexi.com/player/?url="
        }
    ],
    "iptv": [
        {
            "name": "APTV",
            "url": "https://raw.githubusercontent.com/Kimentanm/aptv/master/m3u/iptv.m3u",
            "epg": "https://epg.112114.xyz/"
        }
    ],
    "channel": [
        {
            "name": "CCTV1",
            "logo": "https://epg.112114.xyz/logo/CCTV1.png",
            "url": "http://tvpull.dxhmt.cn/tv/11481-4.m3u8"
        }
    ],
    "sites": [
        {
            "key": "39kan",
            "name": "39影视",
            "api": "https://www.39kan.com/api.php/provide/vod/",
            "download": "",
            "jiexiUrl": "",
            "playUrl": "",
            "group": "切片",
            "type": 1
        }
    ]
}
*/
