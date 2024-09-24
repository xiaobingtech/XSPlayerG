//
//  XS_NetIptv.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/18.
//

import Foundation
import Alamofire

extension XS_NetWork {
    /**
     * 获取电子节目单
     * @param {*} url epg阶段单api
     * @param {*} tvg_name 节目名称
     * @param {*} date 日期 2023-01-31
     * @returns 电子节目单列表
     */
    func iptvEpg(url: String, tvg_name: String, date: String) async throws -> [XS_VideoModel] {
        let dict: NSDictionary
        switch await request(url, parameters: ["ch" : tvg_name, "date" : date]).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let j = XS_IptvEpgModel.deserialize(from: dict) else {
            throw XS_Error.invalidData
        }
        return j.data.epg_data
    }
    
    /**
     * 判断 m3u8 文件是否为直播流
     * @param {*} url m3u8地址
     * @returns 是否是直播流
     */
    func isLiveM3U8(url: String) async throws -> Bool {
        let string: String
        switch await requestString(url).result {
        case let .success(data):
            string = data.uppercased()
        case let .failure(error):
            throw error
        }
        
        let conditions: [String] = ["#EXT-X-ENDLIST", "#EXT-X-PLAYLIST-TYPE:VOD", "#EXT-X-MEDIA-SEQUENCE:0"]
        for condition in conditions {
            if string.contains(condition) {
                return false
            }
        }
        return true
    }
    
    func iptvList(_ url: String, isWeb: Bool = false) async throws -> [XS_IptvGroupModel] {
        let errorResult: (Error) async throws -> [XS_IptvGroupModel]
        let data: String
        if isWeb {
            errorResult = { throw $0 }
            data = try await XS_NetWeb.request(url)
        } else {
            let url = url.xs_urlString()
            errorResult = { _ in try await self.iptvList(url, isWeb: true) }
            let value: Data
            switch await request(url).result {
            case let .success(data):
                value = data
            case let .failure(error):
                return try await errorResult(error)
            }
            guard let text = String(data: value, encoding: .utf8) else {
                return try await errorResult(XS_Error.invalidData)
            }
            data = text
        }
        
        let text = data.trimmingCharacters(in: .whitespacesAndNewlines)
        let list: [XS_IptvGroupModel]
        if text.hasPrefix("#EXTM3U") {
            list = m3u(text)
        } else {
            list = txt(text)
        }
        if list.isEmpty {
            return try await errorResult(XS_Error.invalidData)
        }
        return list
    }
    private func m3u(_ text: String) -> [XS_IptvGroupModel] {
        class _M {
            var line: String = ""
            var url: String = ""
            var toModel: XS_IptvItemModel? {
                if url.isEmpty { return nil }
                do {
                    let groupRegex = "group-title=\"([^\"]*)\""
                    let logoRegex = "tvg-logo=\"(.*?)\""
                    let nameRegex = ".*,(.+?)(?:$|\\n|\\s)"
                    let name = String((try line.xs_matches(with: nameRegex).first?.split(separator: ",").last) ?? "")
                    let logo = getStr(try line.xs_matches(with: logoRegex).first)
                    let group = getStr(try line.xs_matches(with: groupRegex).first)
                    return XS_IptvItemModel(name: name, logo: logo, group: group, url: url)
                } catch {
                    return nil
                }
            }
            private func getStr(_ text: String?) -> String {
                guard let text = text, let index = text.firstIndex(of: "=") else {
                    return ""
                }
                let start = text.index(after: index)
                let end = text.index(before: text.endIndex)
                if end > start {
                    return String(text[start...end])
                }
                return ""
            }
        }
        var groups: [String] = []
        var dic: [String:[XS_IptvItemModel]] = [:]
        var model = _M()
        for line in text.split(separator: "\n") {
            if line.hasPrefix("#EXTINF:") {
                model = _M()
                model.line = String(line)
            } else if line.contains("://") {
                if line.hasPrefix("#EXT-X-SUB-URL") || line.hasPrefix("#EXTM3U") {
                    continue
                }
                model.url = String(line)
                if let model = model.toModel {
                    if !groups.contains(model.group) {
                        groups.append(model.group)
                    }
                    var list = dic[model.group] ?? []
                    list.append(model)
                    dic[model.group] = list
                }
            }
        }
        return groups.compactMap { title in
            guard let list = dic[title] else { return nil }
            return XS_IptvGroupModel(title: title, list: list)
        }
    }
    private func txt(_ text: String) -> [XS_IptvGroupModel] {
        var list: [XS_IptvGroupModel] = []
        for line in text.split(separator: "\n") {
            let split = line.split(separator: ",")
            if split.count < 2 { continue }
            if line.contains("#genre#") {
                list.append(XS_IptvGroupModel(title: String(split[0])))
            }
            if split[1].contains("://") {
                if list.isEmpty {
                    list.append(XS_IptvGroupModel(title: "默认"))
                }
                let item = XS_IptvItemModel(name: String(split[0]), logo: "", group: list.last!.title, url: String(split[1]))
                list[list.endIndex - 1].list.append(item)
            }
        }
        return list
    }
}
