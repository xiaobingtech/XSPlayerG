//
//  XS_SetOtherView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/21.
//

import SwiftUI
import SwiftData

struct XS_SetOtherView: View {
    @Environment(\.modelContext) private var modelContext
//    @Query private var analyzeData: [XS_SDAnalyze]
//    @Query private var iptvData: [XS_SDIptv]
//    @Query private var siteData: [XS_SDSite]
    @Query private var groupData: [XS_SDSiteGroup]
    
    var body: some View {
        List {
            XS_SetGreen(text: "绿色模式")
            Section {
                _Text(text: "影视资源重置", action: resetSite)
                _Text(text: "电视资源重置", action: resetIptv)
                _Text(text: "解析资源重置", action: resetJx)
            } header: {
                Text("资源")
            }
            Section {
                NavigationLink(item: .setTest) {
                    Text("前往一键检测")
                }
            } header: {
                Text("检测")
            }
        }
        .navigationTitle("其他设置")
    }
    
    private func resetSite() -> Bool {
        guard let model = XS_ResourcesModel.rescources else { return true }
        for item in groupData {
            modelContext.delete(item)
        }
//        try? modelContext.delete(model: XS_SDSiteGroup.self)
        var group: [XS_SDSiteGroup] = []
        var sort: [XS_SDSiteGroup:Int] = [:]
        var arr: [String] = []
        for item in model.sites {
            guard !item.api.isEmpty, !arr.contains(item.api) else { continue }
            arr.append(item.api)
            let key = item.group.isEmpty ? "未分组" : item.group
            let g: XS_SDSiteGroup
            if let item = group.first(where: { $0.name == key }) {
                g = item
            } else {
                let new = XS_SDSiteGroup(name: key, sort: group.count)
                g = new
                group.append(new)
                modelContext.insert(new)
            }
            let index = sort[g] ?? 0
            sort[g] = index + 1
            let new = XS_SDSite(name: item.name, api: item.api, download: item.download, playUrl: item.playUrl.isEmpty ? item.jiexiUrl : item.playUrl, type: .init(rawValue: item.type) ?? .cms_xml, sort: index)
            modelContext.insert(new)
            new.group = g
        }
        return false
    }
    private func resetIptv() -> Bool {
        guard let model = XS_ResourcesModel.rescources else { return true }
        try? modelContext.delete(model: XS_SDIptv.self)
        var arr: [String] = []
        for (index, item) in model.iptv.enumerated() {
            guard !item.url.isEmpty, !arr.contains(item.url) else { continue }
            arr.append(item.url)
            let new = XS_SDIptv(name: item.name, url: item.url, epg: item.epg, sort: index)
            modelContext.insert(new)
        }
        return false
    }
    private func resetJx() -> Bool {
        guard let model = XS_ResourcesModel.rescources else { return true }
        try? modelContext.delete(model: XS_SDAnalyze.self)
        var arr: [String] = []
        for (index, item) in model.analyze.enumerated() {
            guard !item.url.isEmpty, !arr.contains(item.url) else { continue }
            arr.append(item.url)
            let new = XS_SDAnalyze(name: item.name, url: item.url, sort: index)
            modelContext.insert(new)
        }
        return false
    }
}

struct XS_SetGreen: View {
    let text: String
    @Query private var searchData: [XS_SDSiteSearch]
    var body: some View {
        if let search = searchData.first {
            Section {
                HStack {
                    Text(text)
                    Spacer()
                    Toggle("", isOn: .init(get: { search.is18 }, set: {
                        search.is18 = $0
                        xs_r18KeyWords = $0 ? xs_r18 : []
                    })).fixedSize()
                }
            } header: {
                Text("通用")
            }
        }
    }
}

private struct _Text: View {
    let text: String
    let action: () -> Bool
    @State private var canReset: Bool = true
    var body: some View {
        Button {
            canReset = action()
        } label: {
            HStack {
                Text(text)
                    .foregroundStyle(Color(uiColor: .label))
                Spacer()
                Text(canReset ? "reset" : "done")
            }
        }
        .disabled(!canReset)
    }
}
