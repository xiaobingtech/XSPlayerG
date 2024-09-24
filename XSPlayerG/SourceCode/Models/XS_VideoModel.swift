//
//  XS_VideoModel.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/16.
//

import Foundation

class XS_VideoModel: XS_Model, Hashable, Identifiable {
    func hash(into hasher: inout Hasher) { (isList ? vod_id + "$isList" : vod_id).hash(into: &hasher) }
    static func == (lhs: XS_VideoModel, rhs: XS_VideoModel) -> Bool {
        lhs.vod_id == rhs.vod_id && lhs.isList == rhs.isList
    }
    var isList: Bool = true
    var vod_id: String = ""
    var type_id: String = ""
    var type_name: String = ""
    var vod_pic: String = ""
    var vod_remark: String = ""
    var vod_name: String = ""
    var vod_blurb: String = ""
    var vod_year: String = ""
    var vod_area: String = ""
    var vod_content: String = ""
    var vod_director: String = ""
    var vod_actor: String = ""
    
    var vod_en: String = ""
    var vod_time: String = ""
    var vod_remarks: String = ""
    var vod_play_from: String = ""
    
    var vod_play_url: String = ""
    
    var vod_hot: Int = 0
    
    var xs_hot: String {
        vod_hot > 0 ? "热度: \(vod_hot)" : xs_remark
    }
    var xs_time: String {
        let date: Date
        if vod_time.contains("-") {
            let fm = DateFormatter()
            fm.dateFormat = "yyyy-MM-dd HH:mm:ss"
            guard let fmDate = fm.date(from: vod_time.trimmingCharacters(in: .whitespacesAndNewlines)) else { return vod_time }
            date = fmDate
        } else if let time = TimeInterval(vod_time) {
            date = Date(timeIntervalSince1970: time)
        } else {
            return vod_time
        }
        return date.xs_time
    }
    var xs_remark: String {
        vod_remarks.isEmpty ? vod_remark : vod_remarks
    }
    var xs_content: String {
        vod_blurb.isEmpty ? vod_content.xs_removeHTMLTags() : vod_blurb
    }
    var xs_tags: String {
        [vod_year, vod_area, type_name].filter { !$0.isEmpty }.joined(separator: "·")
    }
    var fullList: [String:[String]] {
        // 播放源
        let playSource = vod_play_from.split(separator: "$").compactMap { item in
            item.isEmpty ? nil : String(item)
        }
        // 剧集
        let playEpisodes = vod_play_url.split(separator: "$$$").compactMap { item in
            String(item).xs_replace(of: "\\$+", with: "$")
                .split(separator: "#")
                .compactMap { item in
                    item.contains("$") ? String(item) : "正片$\(item)"
                }
        }
        return zip(playSource, playEpisodes).reduce(into: [:]) { partialResult, item in
            partialResult[item.0] = item.1
        }
    }
}

extension Date {
    var xs_time: String {
        let current = Calendar.current
        if current.compare(self, to: Date(timeIntervalSinceNow: -600), toGranularity: .minute) == .orderedDescending {
            return "刚刚"
        }
        if current.compare(self, to: Date(timeIntervalSinceNow: -1800), toGranularity: .minute) == .orderedDescending {
            return "半小时"
        }
        if current.compare(self, to: Date(timeIntervalSinceNow: -3600), toGranularity: .minute) == .orderedDescending {
            return "一小时"
        }
        if current.compare(self, to: Date(timeIntervalSinceNow: -3600), toGranularity: .minute) == .orderedDescending {
            return "一小时"
        }
        if current.compare(self, to: Date(timeIntervalSinceNow: -10800), toGranularity: .minute) == .orderedDescending {
            return "三小时"
        }
        if current.isDateInToday(self) {
            return "今天"
        }
        if current.isDateInYesterday(self) {
            return "昨天"
        }
        let now = Date.now
        if current.compare(self, to: now, toGranularity: .month) == .orderedSame {
            return "当月"
        }
        if current.compare(self, to: now, toGranularity: .year) == .orderedSame {
            return "今年"
        }
        let fm = DateFormatter()
        fm.dateFormat = "yyyy-MM-dd"
        return fm.string(from: self)
    }
}
