//
//  XS_SiteModel.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/15.
//

import Foundation
import SwiftHash
import HandyJSON

struct XS_SiteM: Hashable {
    var name: String
    var api: String
//    var download: String
    var playUrl: String
    var type: XS_SDSite._Type?
}
enum XS_ListM<T> {
    case noMore([T])
    case list([T])
}

class XS_SiteModel: XS_Model, Hashable, Identifiable {
    func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
    static func == (lhs: XS_SiteModel, rhs: XS_SiteModel) -> Bool {
        lhs.id == rhs.id
    }
    var name: String = ""
    var api: String = "" {
        didSet {
            if oldValue == api { return }
            _id = nil
        }
    }
    var jiexiUrl: String = "" {
        didSet {
            if oldValue == api { return }
            _id = nil
        }
    }
    var playUrl: String = ""
    var group: String = ""
    var isActive: Bool = true
    var type: _Type?
    enum _Type: Int, HandyJSONEnum {
        case cms_xml = 0
        case cms_json
        case drpy_js0
        case app_v3
        case app_v1
    }
    
    var id: String { _id ?? upId() }
    private var _id: String?
    @discardableResult
    private func upId() -> String {
        let value = MD5("{api:'\(api)'}{jiexiUrl:'\(jiexiUrl)'}")
        _id = value
        return value
    }
    
    var is18: Bool = false
    
    static var all: XS_SiteModel {
        let model = XS_SiteModel()
        model.name = "全部"
        return model
    }
    static var test_xml: XS_SiteModel {
        let model = XS_SiteModel()
        model.name = "U酷资源"
        model.api = "https://api.ukuapi.com/api.php/provide/vod/at/xml"
        model.type = .cms_xml
        return model
    }
    static var test_app3: XS_SiteModel {
        let model = XS_SiteModel()
        model.name = "KUIN"
        model.api = "https://www.kuin.one/api.php/app"
        model.type = .app_v3
        return model
    }
}

class XS_FilmModel: XS_Model, Equatable {
    static func == (lhs: XS_FilmModel, rhs: XS_FilmModel) -> Bool {
        lhs.classData == rhs.classData
    }
    var xs_classData: [ClassData] {
        classData.filter { $0.type_name.is18 }
    }
    var classData: [ClassData] = []
    class ClassData: XS_Model, Hashable, Identifiable {
        func hash(into hasher: inout Hasher) { type_id.hash(into: &hasher) }
        static func == (lhs: XS_FilmModel.ClassData, rhs: XS_FilmModel.ClassData) -> Bool {
            lhs.type_id == rhs.type_id && lhs.type_name == rhs.type_name
        }
        var type_id: String = ""
        var type_name: String = ""
        var type_extend: [String:String]?
        init(type_id: String, type_name: String, type_extend: [String : String]? = nil) {
            self.type_id = type_id
            self.type_name = type_name
            self.type_extend = type_extend
        }
        required init() {}
    }
    var page: Int =  1
    var pagecount: Int = 9999
    var limit: Int = 20
    var total: Int = 9999
    var filters: [String:[_FilterData]] = [:]
    class _FilterData: XS_Model, Equatable, Identifiable {
        static func == (lhs: XS_FilmModel._FilterData, rhs: XS_FilmModel._FilterData) -> Bool {
            lhs.key == rhs.key
        }
        var key: String = ""
        var name: String = ""
        var value: [_Value] = []
        class _Value: XS_Model, Hashable, Identifiable {
            func hash(into hasher: inout Hasher) { v.hash(into: &hasher) }
            static func == (lhs: XS_FilmModel._FilterData._Value, rhs: XS_FilmModel._FilterData._Value) -> Bool {
                lhs.v == rhs.v
            }
            var n: String = ""
            var v: String = ""
            init(n: String, v: String = "") {
                self.n = n
                self.v = v
            }
            required init() {}
        }
        init(key: String, name: String, value: [_Value]) {
            self.key = key
            self.name = name
            self.value = value
        }
        required init() {}
    }
}

class XS_XMLModel: XS_Model {
    class _Text: XS_Model {
        var text: String = ""
    }
//    var version: String = ""
    var `class`: _Class = .init()
    class _Class: XS_Model {
        var ty: [_Ty] = []
        class _Ty: _Text {
            var id: String = ""
        }
        override func mapping(mapper: HelpingMapper) {
            mapper <<< ty <-- safeArray()
        }
    }
    var list: _List = .init()
    class _List: XS_Model {
        var page: Int = 0
        var pagecount: Int = 0
        var pagesize: Int = 0
        var recordcount: Int = 0
        var video: [_Video] = []
        class _Video: XS_Model {
            var id: _Text = .init()
            var tid: _Text = .init()
            var name: _Text = .init()
            var type: _Text = .init()
            var dt: _Text = .init()
            var note: _Text = .init()
            var last: _Text = .init()
            
            var pic: _Text = .init()
            var des: _Text = .init()
            var year: _Text = .init()
            var area: _Text = .init()
            var director: _Text = .init()
            var actor: _Text = .init()
            
            var dl: _Dl = .init()
            class _Dl: XS_Model {
                var dd: [_Dd] = []
                class _Dd: _Text {
                    var flag: String = ""
                }
                override func mapping(mapper: HelpingMapper) {
                    mapper <<< dd <-- safeArray()
                }
            }
            
            func xs_toVideoModel() -> XS_VideoModel {
                let model = XS_VideoModel()
                model.vod_id = id.text
                model.type_id = tid.text
                model.type_name = type.text
                model.vod_pic = pic.text
                model.vod_remark = note.text
                model.vod_name = name.text
                model.vod_blurb = des.text.xs_removeHTMLTagsAndSpaces()
                model.vod_year = year.text
                model.vod_area = area.text
                model.vod_content = des.text
                model.vod_director = director.text
                model.vod_actor = actor.text
                
                model.vod_time = last.text
                if dl.dd.isEmpty {
                    model.vod_play_from = dt.text
                } else {
                    model.vod_play_from = dl.dd.compactMap({ $0.flag }).joined(separator: "$$$")
                    model.vod_play_url = dl.dd.compactMap({ $0.text }).joined(separator: "$$$")
                }
                return model
            }
        }
        override func mapping(mapper: HelpingMapper) {
            // xml坑: 单条结果是dict 多条结果list
            mapper <<< video <-- safeArray()
        }
    }
}

class XS_JSONModel: XS_Model {
    var code: Int = 0
    var msg: String = ""
    var page: Int = 0
    var pagecount: Int = 0
    var limit: Int = 0
    var total: Int = 0
    var list: [XS_VideoModel] = []
    var `class`: [XS_FilmModel.ClassData] = []
}

class XS_JSModel: XS_Model {
    var data: _Data = .init()
    class _Data: XS_Model {
        var filters: [String:[XS_FilmModel._FilterData]] = [:]
        var `class`: [XS_FilmModel.ClassData] = []
        var rss: _Rss?
        class _Rss: XS_Model {
            var `class`: [XS_FilmModel.ClassData] = []
        }
    }
}

class XS_V3Model<T>: XS_Model {
    var data: T?
    var list: T?
}
class XS_V3ArrayModel<T: XS_Model>: XS_Model  {
    var data: [T]?
    var list: [T]?
    override func mapping(mapper: HelpingMapper) {
        mapper <<< data <-- safeArray()
        mapper <<< list <-- safeArray()
    }
    var xs_value: [T] {
        if let value = data, !value.isEmpty {
            return value
        }
        if let value = list, !value.isEmpty {
            return value
        }
        return []
    }
}

class XS_V1Model<T>: XS_Model {
    var data: _Data = .init()
    class _Data: XS_Model {
        var list: T?
    }
    var xs_value: T? { data.list }
}

class XS_V1DataModel: XS_Model {
    var data: _Data = .init()
    class _Data: XS_Model {
        var limit: Int = 0
        var total: Int = 0
    }
}

class XS_RealUrlModel: XS_Model {
    var redirect: Bool = false
    var url: String = ""
}
