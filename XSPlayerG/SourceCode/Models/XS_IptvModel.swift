//
//  XS_IptvModel.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/18.
//

import Foundation

class XS_IptvModel: XS_Model, Hashable {
    func hash(into hasher: inout Hasher) { url.hash(into: &hasher) }
    static func == (lhs: XS_IptvModel, rhs: XS_IptvModel) -> Bool {
        lhs.name == rhs.name && lhs.url == rhs.url
    }
    var name: String = ""
    var url: String = ""
    var epg: String = ""
    
    static var test_agit: Self {
        let model = Self()
        model.name = "agit:66666"
        model.url = "https://agit.ai/66666/mao/raw/branch/master/live20220813.txt"
        model.epg = ""
        return model
    }
    static var test_秋天直播: Self {
        let model = Self()
        model.name = "秋天直播"
        model.url = "https://pan.shangui.cc/f/XR6dud/%E7%A7%8B%E5%A4%A9%E7%9B%B4%E6%92%AD.txt"
        model.epg = ""
        return model
    }
    static var test_茶客: Self {
        let model = Self()
        model.name = "茶客"
        model.url = "https://mirror.ghproxy.com/https://raw.githubusercontent.com/vamoschuck/TV/main/M3U"
        model.epg = "https://epg.112114.eu.org/"
        return model
    }
    static var test_IPV6专用: Self {
        let model = Self()
        model.name = "IPV6专用"
        model.url = "https://ghproxy.com/https://raw.githubusercontent.com/YueChan/IPTV/main/IPTV.m3u"
        model.epg = "http://epg.112114.xyz"
        return model
    }
    
    
    static var test_解析1: Self {
        let model = Self()
        model.name = "解析1"
        model.url = "https://jx.777jiexi.com/player/?url="
        return model
    }
    static var test_解析25: Self {
        let model = Self()
        model.name = "解析2"
        model.url = "https://www.playm3u8.cn/jiexi.php?url="
        return model
    }
    static var test_解析26: Self {
        let model = Self()
        model.name = "解析3"
        model.url = "https://api.jiexi.la/?url="
        return model
    }
    static var test_解析27: Self {
        let model = Self()
        model.name = "解析4"
        model.url = "https://www.8090g.cn/?url="
        return model
    }
}

class XS_IptvEpgModel: XS_Model {
    var data: _Data = .init()
    class _Data: XS_Model {
        var epg_data: [XS_VideoModel] = []
    }
}

struct XS_IptvGroupModel: Hashable {
    var title: String
    var list: [XS_IptvItemModel] = []
}

struct XS_IptvItemModel: Hashable {
    var name: String
    var logo: String
    var group: String
    var url: String
}
