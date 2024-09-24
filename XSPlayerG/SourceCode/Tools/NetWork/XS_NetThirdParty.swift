//
//  XS_NetThirdParty.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/18.
//

import Foundation
import HTMLReader
import Alamofire

// MARK: - 豆瓣
extension XS_NetWork {
    /**
     * 获取豆瓣页面链接
     * @param {*} id 视频唯一标识
     * @param {*} name 视频名称
     * @param {*} year 视频年份
     * @returns 豆瓣页面链接，如果没有搜到该视频，返回搜索页面链接
     */
    func doubanLink(id: String? = nil, name: String = "", year: String = "") async throws -> String {
        if let id = id, !id.isEmpty, id != "0" {
            return "https://movie.douban.com/subject/\(id)"
        }
        
        let q = name.xs_urlString()
        let string: String
        switch await requestString("https://www.douban.com/search?cat=1002&q=\(q)").result {
        case let .success(data):
            string = data
        case let .failure(error):
            throw error
        }
        
        let document = HTMLDocument(string: string)
        guard let result_list = document.nodes(matchingSelector: "div").first(where: { $0.attributes["class"] == "result-list" }) else {
            throw XS_Error.invalidData
        }
        
        for result in result_list.childElementNodes {
            if let a = result.firstNode(matchingSelector: "h3")?.firstNode(matchingSelector: "a"),
               a.textContent.xs_urlString() == q,
               let subject_cast = result.nodes(matchingSelector: "span").first(where: { $0.attributes["class"] == "subject-cast" }),
               subject_cast.textContent.contains(year),
               let href = a.attributes["href"] {
                return href
            }
        }
        throw XS_Error.invalidData
    }
    
    func doubanDocument(id: String? = nil, name: String = "", year: String = "") async throws -> HTMLDocument {
        let link = try await doubanLink(id: id, name: name, year: year)
        switch await requestString(link).result {
        case let .success(data):
            return HTMLDocument(string: data)
        case let .failure(error):
            throw error
        }
    }
    
    /**
     * 获取豆瓣评分
     * @param {*} id 视频唯一标识
     * @param {*} name 视频名称
     * @param {*} year 视频年份
     * @returns 豆瓣评分
     */
    func doubanRate(_ document: HTMLDocument) throws -> String {
        guard let interest_sectl = document.nodes(matchingSelector: "div").first(where: { $0.attributes["id"] == "interest_sectl" }), let strong = interest_sectl.firstNode(matchingSelector: "strong") else {
            throw XS_Error.invalidData
        }
        return strong.textContent
    }
    func doubanRate(id: String? = nil, name: String = "", year: String = "") async throws -> String {
        return try await doubanRate(doubanDocument(id: id, name: name, year: year))
    }
    
    /**
     * 获取豆瓣相关视频推荐列表
     * @param {*} id 视频唯一标识
     * @param {*} name 视频名称
     * @param {*} year 视频年份
     * @returns 豆瓣相关视频推荐列表
     */
    func doubanRecommendations(_ document: HTMLDocument) throws -> [XS_DoubanRecommendModel] {
        guard let recommendations_bd = document.nodes(matchingSelector: "div").first(where: { $0.attributes["class"] == "recommendations-bd" }) else {
            throw XS_Error.invalidData
        }
//        return recommendations_bd.nodes(matchingSelector: "dd").compactMap {
//            $0.firstNode(matchingSelector: "a")?.textContent
//        }
        return recommendations_bd.nodes(matchingSelector: "dl").compactMap { dl in
            guard let dt = dl.firstNode(matchingSelector: "dt"), let img = dt.firstNode(matchingSelector: "img"), let dd = dl.firstNode(matchingSelector: "dd"), let a = dd.firstNode(matchingSelector: "a"), let span = dd.firstNode(matchingSelector: "span") else {
                return nil
            }
            let model = XS_DoubanRecommendModel()
            model.img = img.attributes["src"] ?? ""
            model.name = a.textContent
            model.score = span.textContent
            return model
        }
    }
    func doubanRecommendations(id: String? = nil, name: String = "", year: String = "") async throws -> [XS_DoubanRecommendModel] {
        return try await doubanRecommendations(doubanDocument(id: id, name: name, year: year))
    }
    
    func doubanRR(id: String? = nil, name: String = "", year: String = "") async throws -> (String, [XS_DoubanRecommendModel]) {
        let document = try await doubanDocument(id: id, name: name, year: year)
        return try (doubanRate(document), doubanRecommendations(document))
    }
    
    /**
     * 获取豆瓣热点视频列表
     * @param {*} type 类型
     * @param {*} tag 标签
     * @param {*} limit 显示条数
     * @param {*} start 跳过
     * @returns 豆瓣热点视频推荐列表
     */
    func doubanHot(type: String = "tv", tag: String = "热门", limit: Int = 10, start: Int = 0) async throws -> [XS_VideoModel] {
        let url = "https://movie.douban.com/j/search_subjects?type=\(type)&tag=\(tag.xs_urlString())&page_limit=\(limit)&page_start=\(start)"
        
        let dict: NSDictionary
        switch await request(url).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_DoubanHotModel.deserialize(from: dict) else {
            throw XS_Error.invalidData
        }
        return model.subjects.compactMap { $0.xs_toVideoModel() }
    }
}

// MARK: - 夸克
extension XS_NetWork {
    /**
     * 获取夸克电影实时热门列表
     * @returns 夸克电影实时热门列表
     */
    func quarkHot() async throws -> [XS_VideoModel] {
        let url = "https://com-cms.quark.cn/cms?partner_id=quark-covid&group=quark-covid&uc_param_str=dnfrpfbivessbtbmnilauputogpintnwmtsvcppcprsnnnchmicckpgi&uid="
        
        let dict: NSDictionary
        switch await request(url).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_QuarkHotModel.deserialize(from: dict),
              let item = model.data.allUserRes.hot_search_movie.first?.items.first  else {
            throw XS_Error.invalidData
        }
        return item.list.compactMap { $0.xs_toVideoModel() }
    }
}

// MARK: - 百度
extension XS_NetWork {
    /**
     * 获取百度实时热门列表
     * @returns 百度实时热门列表
     */
    func baiduHot() async throws -> [XS_VideoModel] {
        let url = "https://opendata.baidu.com/api.php?resource_id=51274&ks_from=aladdin&new_need_di=1&from_mid=1&sort_type=1&query=%E7%94%B5%E8%A7%86%E5%89%A7%E6%8E%92%E8%A1%8C%E6%A6%9C&tn=wisexmlnew&dsp=iphone&format=json&ie=utf-8&oe=utf-8&q_ext=%7B%22query_key%22%3A1%2C%22is_person_related%22%3A0%2C%22video_type_list%22%3A%5B%5D%7D&sort_key=1&stat0=%E7%94%B5%E8%A7%86%E5%89%A7&stat1=%E5%85%A8%E9%83%A8&stat2=%E5%85%A8%E9%83%A8&stat3=%E5%85%A8%E9%83%A8&rn=10&pn=0&trigger_srcid=51251&sid=38515_36559_38540_38591_38596_38582_36804_38434_38414_38640_26350_38623"
        
        let dict: NSDictionary
        switch await request(url).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_BaiduHotModel.deserialize(from: dict),
              model.ResultCode == 0,
              let result = model.Result.first else {
            throw XS_Error.invalidData
        }
        return result.DisplayData.resultData.tplData.result.result.compactMap { $0.xs_toVideoModel() }
    }
}

// MARK: - 酷云
extension XS_NetWork {
    /**
     * 获取酷云[新]热榜列表
     * @param {*} date 日期2023-05-03 必须补全0
     * @param {*} type 类型 1.全端播放  2.全端热度  3.实时收视  4.历史收视
     * @param {*} plat 平台 0.全端热度  1.爱奇艺  2.腾讯视频  3.优酷  4.芒果
     * @returns 酷云[新]热榜推荐列表
     */
    func kyLiveHot(date: Date = Date(), type: XS_KyLiveHotType = .全端热度, plat: XS_KyLiveHotPlat = .全端热度) async throws -> [XS_VideoModel] {
        let fm = DateFormatter()
        fm.dateFormat = "YYYY-MM-DD"
        let url = "https://www.ky.live/api/fullhot?vt=\(type.rawValue)&sd=\(fm.string(from: date))&plt=\(plat.rawValue)"
        
        let dict: NSDictionary
        switch await request(url).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_KyLiveHotModel.deserialize(from: dict),
              model.status else {
            throw XS_Error.invalidData
        }
        return model.data.compactMap { $0.xs_toVideoModel() }
    }
    enum XS_KyLiveHotType: Int {
        case 全端播放 = 1, 全端热度, 实时收视, 历史收视
    }
    enum XS_KyLiveHotPlat: Int {
        case 全端热度 = 0, 爱奇艺, 腾讯视频, 优酷, 芒果
    }
}

// MARK: - 云合
extension XS_NetWork {
    /**
     * 获取云合热榜列表
     * @param {*} date 日期2023/07/28  sort为allHot 忽略该参数
     * @param {*} channelType 类型 tv:连续剧  art:综艺  movie.电影  tvshortVideo.微短剧  animation.动漫
     * @param {*} sort 排序 allHot:全舆情热度  spreadHot:话题传播度  searchHot:搜索热度  feedbackHot:反馈活跃度
     * @param {*} day  最近几天
     * @returns 云合热榜推荐列表
     */
    func enlightentHot(sort: XS_EnlightentHotSort = .全舆情热度, channelType: XS_EnlightentHotType = .连续剧, day: Int = 1) async throws -> [XS_VideoModel] {
        let url = "https://www.enlightent.cn/sxapi/top/getHeatTop.do"
        
        let dict: NSDictionary
        switch await request(url, parameters: [
            "sort" : sort.rawValue,
            "channelType" : channelType.rawValue,
            "day" : day
        ]).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_EnlightentHotModel.deserialize(from: dict),
              !model.content.isEmpty else {
            throw XS_Error.invalidData
        }
        return model.content.compactMap { $0.xs_toVideoModel() }
    }
    enum XS_EnlightentHotType: String, CaseIterable, Hashable {
        case 连续剧 = "tv"
        case 综艺 = "art"
        case 电影 = "movie"
        case 微短剧 = "tvshortVideo"
        case 动漫 = "animation"
        var name: String {
            switch self {
            case .连续剧: return "连续剧"
            case .综艺: return "综艺"
            case .电影: return "电影"
            case .微短剧: return "微短剧"
            case .动漫: return "动漫"
            }
        }
    }
    enum XS_EnlightentHotSort: String {
        case 全舆情热度 = "allHot"
        case 话题传播度 = "spreadHot"
        case 搜索热度 = "searchHot"
        case 反馈活跃度 = "feedbackHot"
    }
}


