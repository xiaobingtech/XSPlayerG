//
//  XS_NetSiteHot.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/16.
//

import Foundation

extension XS_NetWork {
    /**
     * 获取资源热榜列表
     * @param {*} key 资源网 key
     * @param {number} [pg=1] 翻页 page
     * @param {*} t 分类 type
     * @param {*} h 时间 time
     * @returns
     */
    func hot(site: XS_SiteM, h: Int = 24*7) async throws -> [XS_VideoModel] {
        let url: String
        switch site.type {
        case .none:
            throw XS_Error.invalidType
        case .app_v3:
            url = try site.api.xs_buildUrl("/index_video")
        default:
            url = try site.api.xs_buildUrl("?ac=hot&h=\(h)")
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
        return try hotList(site: site, jsondata: jsondata)
    }
    
    private func hotList(site: XS_SiteM, jsondata: NSDictionary) throws -> [XS_VideoModel] {
        let videoList: [XS_VideoModel]
        switch site.type! {
        case .cms_xml:
            guard let x = XS_XMLModel.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            videoList = x.list.video.compactMap { $0.xs_toVideoModel() }
        case .cms_json, .drpy_js0, .app_v1:
            guard let j = XS_V3ArrayModel<XS_VideoModel>.deserialize(from: jsondata) else {
                throw XS_Error.invalidData
            }
            videoList = j.xs_value
        case .app_v3:
            guard let arr = jsondata["list"] as? NSArray else {
                throw XS_Error.invalidData
            }
            videoList = arr.reduce(into: []) { partialResult, item in
                guard let dic = item as? NSDictionary, let vlist = dic["vlist"] else {
                    return
                }
                if let vlist = vlist as? NSDictionary, let data = XS_VideoModel.deserialize(from: vlist) {
                    partialResult.append(data)
                    return
                }
                if let vlist = vlist as? [NSDictionary] {
                    partialResult += vlist.compactMap { XS_VideoModel.deserialize(from: $0) }
                    return
                }
            }
        }
        // cms_xml cms_json app_v1 需要获取详情图片 再取前 10
        return Array(videoList.prefix(10))
    }
}
