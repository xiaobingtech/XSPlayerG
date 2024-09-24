//
//  XS_NetCheck.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/18.
//

import Foundation
import HTMLReader
import Network
import Alamofire

extension XS_NetWork {
    /**
     * 检查资源
     * @param {*} key 资源网 key
     * @returns boolean
     */
    func check(site: XS_SiteM) async throws -> Bool {
        let data = try await classify(site: site)
        return !data.classData.isEmpty
    }
    
    /**
     * 检查直播源
     * @param {*} channel 直播频道 url
     * @returns boolean
     */
    func checkChannel(url: String) async throws -> Bool {
        let dict: NSDictionary
        switch await request(url).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        return dict["duration"] != nil
    }
    
    /**
     * 判断url是否为ipv6
     * @param {String} url  请求地址
     * @return {Boolean}
     */
    func checkUrlIpv6(url: String) -> XS_URLIpType {
        if let _ = IPv4Address(url) {
            return .IPv4
        }
        if let _ = IPv6Address(url) {
            return .IPv6
        }
        return .Unknown
    }
    enum XS_URLIpType {
        case IPv4, IPv6, Unknown
    }
}

extension XS_NetWork {
    /**
     * 提取ck/dp播放器m3u8
     * @param {*} parserFilmUrl film url
     * @returns boolean
     */
    func parserFilmUrl(url: String) async throws -> String {
        let string: String
        switch await requestString(url).result {
        case let .success(data):
            string = data
        case let .failure(error):
            throw error
        }
        // 全局提取完整地址
        let urlGlobal = try string.xs_matches(with: "(https?:\\/\\/[^\\s]+\\.m3u8)")
        if let url = urlGlobal.first {
            return url
        }
        // 局部提取地址 提取参数拼接域名
        guard let url = URL(string: url), let hostname = url.xs_hostname  else {
            throw XS_Error.invalidURL
        }
        let urlParm = try string.xs_matches(with: "/.*(\\.m3u8)")
        if let url = urlParm.first {
            return hostname + url
        }
        throw XS_Error.invalidURL
    }
}

// MARK: - 获取
extension XS_NetWork {
    /**
     * 获取解析url链接的标题
     * @param {*} url 需要解析的地址
     * @returns 解析标题
     */
    func getAnalysizeTitle(url: String) async throws -> String {
        let string: String
        switch await request(url).result {
        case let .success(data):
            if url.contains("sohu") {
                let enc = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0632))
                string = String(data: data, encoding: enc)!
            } else {
                string = String(data: data, encoding: .utf8)!
            }
        case let .failure(error):
            throw error
        }
        
        let document = HTMLDocument(string: string)
        
        guard let head = document.firstNode(matchingSelector: "head"), let title = head.firstNode(matchingSelector: "title") else {
            throw XS_Error.invalidData
        }
        return title.textContent
    }
    
    /**
     * 获取配置文件
     * @param {*} url 需要获取的地址
     * @returns 配置文件
     */
    func getConfig(url: URLConvertible, isTry: Bool = false) async throws -> Data {
        switch await request(url).result {
        case let .success(data):
            return data
        case let .failure(error):
            if isTry {
                let url = try await XS_NetWeb.request(url)
                return try await getConfig(url: url)
            }
            throw error
        }
    }
    
    /**
     * 获取配置文件
     * @param {*} url 需要获取的地址
     * @returns 配置文件
     */
    func getRealUrl(site: XS_SiteM, url: String) async throws -> String {
        guard let api = URL(string: site.api), let hostname = api.xs_hostname  else {
            throw XS_Error.invalidURL
        }
        let parsueUrl = hostname + "/web/302redirect?url=\(url.xs_urlString())"
        
        let dict: NSDictionary
        switch await request(parsueUrl).result {
        case let .success(data):
            dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        case let .failure(error):
            throw error
        }
        
        guard let model = XS_RealUrlModel.deserialize(from: dict), model.redirect else {
            throw XS_Error.invalidData
        }
        return model.url
    }
}

extension XS_NetWork {
    func check(url: String) async -> Bool {
        switch await request(url).result {
        case let .success(data):
            return !data.isEmpty
        case let .failure(error):
            debugPrint(error.localizedDescription)
            return false
        }
    }
}
