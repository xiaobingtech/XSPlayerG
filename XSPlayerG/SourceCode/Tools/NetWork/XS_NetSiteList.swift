//
//  XS_NetSiteList.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/16.
//

import Foundation

extension XS_NetWork {
    /**
     * 获取资源列表
     * @param {*} key 资源网 key
     * @param {number} [pg=1] 翻页 page
     * @param {*} t 分类 type
     * @returns
     */
    func list(site: XS_SiteM, pg: Int = 1, t: String, f: [String:String] = [:]) async throws -> XS_ListM<XS_VideoModel> {
        let url: String
        switch site.type {
        case .drpy_js0:
            if f.isEmpty {
                fallthrough
            }
            let json = try JSONSerialization.data(withJSONObject: f)
            let jsonStr = String(data: json, encoding: .utf8) ?? ""
            url = try site.api.xs_buildUrl("?ac=videolist&t=\(t)&pg=\(pg)&f=\(jsonStr)")
        case .cms_xml, .cms_json:
            url = try site.api.xs_buildUrl("?ac=videolist&t=\(t)&pg=\(pg)")
        case .app_v3:
            url = try site.api.xs_buildUrl("video?tid=\(t)&pg=\(pg)" + (f.isEmpty ? "" : "&\(f.xs_toUrlParams())"))
        case .app_v1:
            url = try site.api.xs_buildUrl("?tid=\(t)&page=\(pg)" + (f.isEmpty ? "" : "&\(f.xs_toUrlParams())"))
        case .none:
            throw XS_Error.invalidType
        }
        
        let dict: NSDictionary
        switch await request(url).result {
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
        let list = try videoList(site: site, jsondata: jsondata)
        let new = list.filter { $0.type_name.is18 }
        if list.count < 10 {
            return .noMore(new)
        } else {
            return .list(new)
        }
    }
    
    private func videoList(site: XS_SiteM, jsondata: NSDictionary) throws -> [XS_VideoModel] {
        switch site.type! {
        case .cms_xml:
            guard let x = XS_XMLModel.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            return x.list.video.compactMap { $0.xs_toVideoModel() }
        case .cms_json, .drpy_js0, .app_v3:
            guard let j = XS_V3ArrayModel<XS_VideoModel>.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            return j.xs_value
        case .app_v1:
            guard let j = XS_V1Model<[XS_VideoModel]>.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            return j.xs_value ?? []
        }
    }
}
