//
//  XS_NetSiteDetail.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/17.
//

import Foundation

extension XS_NetWork {
    /**
     * 获取资源详情
     * @param {*} key 资源网 key
     * @param {*} id 资源唯一标识符 id
     * @returns
     */
    func detail(site: XS_SiteM, id: String) async throws -> [XS_VideoModel] {
        let url: String
        switch site.type {
        case .none:
            throw XS_Error.invalidType
        case .app_v3:
            url = try site.api.xs_buildUrl("/video_detail?id=\(id)")
        case .app_v1:
            url = try site.api.xs_buildUrl("/detail?vod_id=\(id)")
        default:
            url = try site.api.xs_buildUrl("?ac=detail&ids=\(id)")
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
        return try videoList(site: site, jsondata: jsondata)
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
