//
//  XS_NetSiteSearch.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/17.
//

import Foundation

extension XS_NetWork {
    /**
     * 搜索资源
     * @param {*} key 资源网 key
     * @param {*} wd 搜索关键字
     * @returns
     */
    func search(site: XS_SiteM, wd: String, pg: Int = 1) async throws -> XS_ListM<XS_VideoModel> {
        let wd = wd.xs_urlString()
        let url: String
        switch site.type {
        case .none:
            throw XS_Error.invalidType
        case .app_v3:
            url = try site.api.xs_buildUrl("/search?text=\(wd)&pg=\(pg)")
        default:
            url = try site.api.xs_buildUrl("?wd=\(wd)&pg=\(pg)")
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
        let list = try searchList(site: site, jsondata: jsondata)
        let new = list.filter { $0.type_name.is18 }
        if list.count < 10 {
            return .noMore(new)
        } else {
            return .list(new)
        }
    }
    
    private func searchList(site: XS_SiteM, jsondata: NSDictionary) throws -> [XS_VideoModel] {
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
