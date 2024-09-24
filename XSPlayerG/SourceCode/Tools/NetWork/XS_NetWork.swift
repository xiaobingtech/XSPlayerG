//
//  XS_NetWork.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/12.
//

import Foundation
import Alamofire
import HandyJSON

class XS_Model: HandyJSON {
    func mapping(mapper: HelpingMapper) {}
    required init() {}
    // xml坑: 单条结果是dict 多条结果list
    func safeArray<T: HandyJSON>() -> TransformOf<[T], Any> {
        TransformOf<[T], Any>(fromJSON: { json in
            if let value = json as? NSDictionary, let model = T.deserialize(from: value) {
                return [model]
            }
            if let value = json as? NSArray, let arr = [T].deserialize(from: value) {
                return arr.compactMap { $0 }
            }
            return nil
        }, toJSON: { model in
            model?.toJSON()
        })
    }
}

extension Dictionary where Key == String {
    func xs_toUrlParams() -> String {
        reduce(into: [String]()) { partialResult, element in
            partialResult.append("\(element.key)=\(element.value)")
        }.joined(separator: "&")
    }
}
extension Dictionary where Key == String, Value == String {
    mutating func xs_addParams(_ str: String) {
        if str.isEmpty { return }
        var str = str
        if str.hasPrefix("?") || str.hasPrefix("&") {
            str.removeFirst()
        }
        for item in str.components(separatedBy: "&") {
            if let index = item.firstIndex(where: { $0 == "=" }) {
                let key = "\(item.prefix(upTo: index))"
                let value = "\(item.suffix(from: item.index(after: index)))"
                self[key] = value
            }
        }
    }
}

extension String {
    func xs_buildUrl(_ paramsStr: String) throws -> String {
        guard let url = URL(string: self) else {
            throw XS_Error.invalidURL
        }
        let api = url.formatted()
        var params: [String: String] = [:]
        if let str = url.query() {
            params.xs_addParams(str)
        }
        
        let result: String
        switch paramsStr.first {
        case .none:
            result = api
        case "/":
            result = api + paramsStr
        case "?", "&":
            params.xs_addParams(paramsStr)
            result = api + "?" + params.xs_toUrlParams()
        default:
            result = api + "/" + paramsStr
        }
        return result.xs_urlString()
    }
    func xs_replace(of regex: String, with replacement: String) -> String {
        replacingOccurrences(of: regex, with: replacement, options: .regularExpression)
    }
    func xs_remove(with regex: String) -> String {
        xs_replace(of: regex, with: "")
//        let regex = try NSRegularExpression(pattern: pattern, options: [])
//        return regex.stringByReplacingMatches(
//            in: self,
//            range: NSRange(location: 0, length: count),
//            withTemplate: ""
//        )
    }
    func xs_removeTrailingSlash() -> String {
        if hasSuffix("/") {
            var str = self
            str.removeLast()
            return str
        }
        return self
    }
    func xs_removeHTMLTagsAndSpaces() -> String {
        xs_remove(with: "<[^>]+>").xs_remove(with: "\\s+")
    }
    func xs_matches(with pattern: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self, options: .withTransparentBounds, range: NSRange(location: 0, length: count))
        return matches.compactMap { match in
            NSString(string: self).substring(with: match.range)
        }
    }
    func xs_urlString() -> String {
        let str = trimmingCharacters(in: .whitespacesAndNewlines)
        let orgin = str.removingPercentEncoding ?? str
        return orgin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str
    }
    
    func xs_removeHTMLTags() -> String {
       do {
           let data = data(using: .unicode)!
           let attrStr = try NSAttributedString(data: data, options: [.documentType:NSAttributedString.DocumentType.html], documentAttributes: nil)
           return attrStr.string
       } catch {
           print(error.localizedDescription)
           return self
       }
    }
}

extension URL {
    var xs_hostname: String? {
        guard var api = host() else {
            return nil
        }
        if let scheme = scheme {
            api = scheme + "://" + api
        }
        if let port = port {
            api += ":\(port)"
        }
        return api
    }
}

class XS_NetWork {
    static let shared = XS_NetWork()
    
    var site: XS_SiteModel? = XS_SiteModel.test_xml
    
    func request(_ urlStr: URLConvertible, method: HTTPMethod = .get, parameters: Parameters? = nil) async -> DataResponse<Data, AFError> {
        await AF.request(urlStr, method: method, parameters: parameters)
            .validate()
            .serializingData()
            .response
    }
    func requestString(_ urlStr: URLConvertible, parameters: Parameters? = nil) async -> DataResponse<String, AFError> {
        await AF.request(urlStr, parameters: parameters)
            .validate()
            .serializingString()
            .response
    }
    func download(_ urlStr: String) async -> DownloadResponse<Data, AFError> {
        await AF.download(urlStr)
            .validate()
            .serializingData()
            .response
    }
    func downloadString(_ urlStr: String) async -> DownloadResponse<String, AFError> {
        await AF.download(urlStr)
            .validate()
            .serializingString()
            .response
    }
}



/**
 {"
   "sites": {
     "default": 1,
     "data": [
       {"key": "U酷资源", "name":"U酷资源", "api": "https://api.ukuapi.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "奇粹影视", "name":"奇粹影视", "api": "http://www.blssv.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "土剧TV", "name":"土剧TV", "api": "http://tujutv.top/api.php/provide/vod/at/xml","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "XYUI", "name":"XYUI", "api": "http://jx4.xyui.top:7001/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "考拉TV", "name":"考拉TV", "api": "https://ikaola.tv/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "51看剧", "name":"51看剧", "api": "http://www.51kanju.cn/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "乐活影视", "name":"乐活影视", "api": "https://lehootv.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "金鹰资源", "name":"金鹰资源", "api": "http://jinyingzy.com/provide/vod/at/xml","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "冠军资源", "name":"冠军资源", "api": "https://www.cmpzy.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "1080资源库", "name":"1080资源库", "api": "https://api.1080zyku.com/inc/api_mac10.php","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "TOM资源",  "name":"TOM资源", "api": "https://api.tomcaiji.com/api.php/provide/vod/at/xml","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "神速资源",  "name":"神速资源", "api": "https://api.sszyapi.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "番茄资源",  "name":"番茄资源", "api": "http://api.fqzy.cc/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "卧龙资源",  "name":"卧龙资源", "api": "https://collect.wolongzyw.com/api.php/provide/vod/at/xml","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "红牛资源",  "name":"红牛资源", "api": "https://www.hongniuzy2.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "想看资源", "name":"想看资源", "api": "https://m3u8.xiangkanapi.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "易看资源", "name":"易看资源", "api": "https://api.yikanapi.com/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "韩剧资源", "name":"韩剧资源", "api": "http://www.hanjuzy.com/inc/apijson_vod.php","type": 1,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "八戒资源", "name":"八戒资源", "api": "http://cj.bajiecaiji.com/inc/apijson_vod.php","type": 1,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "南国影源", "name":"南国影源", "api": "http://api.nguonphim.tv/api.php/provide/vod/at/xml","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "天天影视", "name":"天天影视", "api": "http://tt2022.ga/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "艾思影院", "name":"艾思影院", "api": "https://www.aitee.cc/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "橘猫影视", "name":"橘猫影视", "api": "http://www.zitv.cc/api.php/provide/vod/at/xml","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "速影", "name":"速影", "api": "https://速影128.xyz/inc/apijson.php","type":0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"},
       {"key": "FOX资源", "name":"FOX资源", "api": "https://api.foxzyapi.com/api.","type": 0,"jiexiUrl": "","group": "影视","isActive": true,"status": "true"}
   
     ]
   },
   "iptv": {
     "default": 1,
     "data": [
       {
         "id": 1,
         "name": "饭太硬直播",
         "url": "http://ftyyy.tk/live.txt",
         "epg": "http://epg.51zmt.top:8000/api/diyp/?ch={name}&date={date}",
         "type": "remote",
         "isActive": true
       },
       {
         "id": 2,
         "name": "FongMi直播",
         "type": "remote",
         "url": "http://home.jundie.top:81/Cat/tv/live.txt",
         "epg": "http://epg.51zmt.top:8000/api/diyp/?ch={name}&date={date}",
         "isActive": true
       }
     ]
   },
   "analyzes": {
     "default": 2,
     "data": [
       {"name":"解析1","url":"https://jx.777jiexi.com/player/?url=","isActive": true},
       {"name":"解析2","url":"https://jx.bozrc.com:4433/player/?url=","isActive": true},
       {"name":"解析3","url":"https://www.ckmov.vip/api.php?url=","isActive": true},
       {"name":"解析4","url":"https://www.h8jx.com/jiexi.php?url=","isActive": true},
       {"name":"解析5","url":"https://jx.playerjy.com/?url=","isActive": true},
       {"name":"解析6","url":"https://www.playm3u8.cn/jiexi.php?url=","isActive": true},
       {"name":"解析7","url":"https://api.jiexi.la/?url=","isActive": true},
       {"name":"解析8","url":"https://jx.ivito.cn/?url=","isActive": true},
       {"name":"解析9","url":"https://www.8090g.cn/?url=","isActive": true},
       {"name":"解析10","url":"https://jx.zhanlangbu.com/?url=","isActive": true},
       {"name":"解析11","url":"https://www.ckplayer.vip/jiexi/?url=","isActive": true},
       {"name":"解析12","url":"https://vip.blbo.cc:2222/api/?key=9f230d947680de53b544be747efa8e54&url=","isActive": true},
       {"name":"解析13","url":"https://b.umkan.cc/API.php?url","isActive": true},
       {"name":"解析15","url":"https://jx.zhanlangbu.com/?url=","isActive": true},
       {"name":"解析16","url":"https://h5.freejson.xyz/player/?url=","isActive": true},
       {"name":"解析17","url":"http://jx.fuqizhishi.com:63/API.php?appkey=feimao&url=","isActive": true},
       {"name":"解析18","url":"http://www.pandown.pro/app/tkys/tkysjx.php?url=","isActive": true},
       {"name":"解析19","url":"https://json.xn--9kq078cdn3a.cc/api/?key=9ksb8DzGi6xUtNf1Cm&url=","isActive": true},
       {"name":"解析20","url":"https://jx.ccabc.cc/byg/?url=","isActive": true},
       {"name":"解析21","url":"https://b.umkan.cc/API.php?url=","isActive": true},
       {"name":"解析22","url":"http://45.248.10.163:4433/json.php?wap=0&url=","isActive": true},
       {"name":"解析23","url":"http://newjiexi.gotka.top/keyu3.php?url=","isActive": true},
       {"name":"解析24","url":"http://www.miaoys.cc/vip/?url=","isActive": true},
       {"name":"解析25","url":"http://svip.key521.cn/analysis/json/?uid=22&my=acdgimotxCHLNOTX16&url=","isActive": true},
       {"name":"解析26","url":"http://47.108.39.237:55/api/jsonindex.php/?key=dp2xOsl8Nws8uFdY0E&url=","isActive": true},
       {"name":"解析27","url":"https://okjx.cc/?url=","isActive": true}
     ]
   }
 }
 */
