//
//  XS_NetSite.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/15.
//

import Foundation
import HandyJSON

extension XS_NetWork {
    /**
     * 获取资源分类 和 所有资源的总数, 分页等信息
     * @param {*} key 资源网 key
     * @returns
     */
    func classify(site: XS_SiteM) async throws -> XS_FilmModel {
        let urlStr: String
        switch site.type {
        case .cms_xml, .cms_json:
            urlStr = try site.api.xs_buildUrl("?ac=class")
        case .drpy_js0:
            urlStr = try site.api.xs_buildUrl("&t=1&ac=videolist")
        case .app_v3:
            urlStr = try site.api.xs_buildUrl("/nav")
        case .app_v1:
            urlStr = try site.api.xs_buildUrl("/types")
        case .none:
            throw XS_Error.invalidType
        }
        
        let dict: NSDictionary
        switch await request(urlStr).result {
        case let .success(data):
            if site.type == .cms_xml {
                dict = try XMLReader.dictionary(for: data)
            } else {
                dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
            }
        case let .failure(error):
            throw error
        }
        
        let jsondata = (dict["rss"] as? NSDictionary) ?? dict
        return try await fileModel(site: site, jsondata: jsondata)
    }
    
    private func fileModel(site: XS_SiteM, jsondata: NSDictionary) async throws -> XS_FilmModel {
        let model = XS_FilmModel()
        switch site.type! {
        case .cms_xml:
            guard let x = XS_XMLModel.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            var classData = [XS_FilmModel.ClassData(type_id: "0", type_name: "最新")]
            for item in x.class.ty {
                let data = XS_FilmModel.ClassData(type_id: item.id, type_name: item.text.xs_remove(with: "\\{.*?\\}"))
                classData.append(data)
            }
            model.classData = classData
            model.page = x.list.page
            model.pagecount = x.list.pagecount
            model.limit = x.list.pagesize
            model.total = x.list.recordcount
//            model.filters = filters(from: classData)
        case .cms_json:
            guard let j = XS_JSONModel.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            var classData = j.class
            classData.insert(.init(type_id: "0", type_name: "最新"), at: 0)
            model.classData = classData
            model.page = j.page
            model.pagecount = j.pagecount
            model.limit = j.limit
            model.total = j.total
//            model.filters = filters(from: classData)
        case .drpy_js0:
            let dict: NSDictionary
            switch await request(site.api).result {
            case let .success(data):
                dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
            case let .failure(error):
                throw error
            }
            guard let j = XS_JSONModel.deserialize(from: jsondata), let c = XS_JSModel.deserialize(from: dict)?.data else {
                throw XS_Error.invalidData
            }
            model.classData = c.rss?.class ?? c.class
            model.page = j.page
            model.pagecount = j.pagecount
            model.limit = j.limit
            model.total = j.total
            model.filters = c.filters
        case .app_v3:
            guard let j = XS_V3ArrayModel<XS_FilmModel.ClassData>.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            let classData = j.xs_value
            model.classData = classData
            model.filters = filtersApp(from: classData)
        case .app_v1:
            let dict: NSDictionary
            switch await request(site.api.xs_removeTrailingSlash()).result {
            case let .success(data):
                dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
            case let .failure(error):
                throw error
            }
            guard let j = XS_V1Model<[XS_FilmModel.ClassData]>.deserialize(from: jsondata), let v = XS_V1DataModel.deserialize(from: dict) else {
                throw XS_Error.invalidData
            }
            let classData = j.xs_value ?? []
            model.classData = classData
            model.limit = v.data.limit
            model.total = v.data.total
            model.filters = filtersApp(from: classData)
        }
        return model
    }
    
    private func filtersApp(from classData: [XS_FilmModel.ClassData]) -> [String:[XS_FilmModel._FilterData]] {
        let arr = ["star", "state", "version", "director"]
        return classData.reduce(into: [:]) { filters, item in
            guard let extend = item.type_extend else { return }
            filters[item.type_id] = extend.compactMap { (key, value) in
                if value.isEmpty || arr.contains(key) { return nil }
                var list: [XS_FilmModel._FilterData._Value] = value.split(separator: ",").compactMap { item in
                    let v = item.trimmingCharacters(in:.whitespaces)
                    return v == "全部" ? nil : .init(n: v, v: v)
                }
                list.insert(.init(n: "全部"), at: 0)
                let translateDict = translateDict
                return .init(
                    key: key,
                    name: translateDict[key] ?? key,
                    value: list
                )
            }
        }
    }
    
    private func filters(from classData: [XS_FilmModel.ClassData]) -> [String:[XS_FilmModel._FilterData]] {
        let cmsFilterData = cmsFilterData
        return classData.reduce(into: [:]) { $0[$1.type_id] = cmsFilterData }
    }
    
    private var cmsFilterData: [XS_FilmModel._FilterData] {
        [
            .init(
                key: "area",
                name: "地区",
                value: [
                    .init(n: "全部")
                ]
            ),
            .init(
                key: "year",
                name: "年份",
                value: [
                    .init(n: "全部")
                ]
            ),
            .init(
                key: "sort",
                name: "排序",
                value: [
                    .init(n: "按更新时间", v: "按更新时间"),
                    .init(n: "按上映年份", v: "按上映年份"),
                    .init(n: "按片名", v: "按片名")
                ]
            )
        ]
    }
    
    private var translateDict: [String:String] {
        [
            "area" : "地区",
            "class" : "剧情",
            "director" : "导演",
            "lang" : "语言",
            "star" : "明星",
            "state" : "状态",
            "version" : "版本",
            "year" : "年份",
            "sort" : "排序"
        ]
    }
}
