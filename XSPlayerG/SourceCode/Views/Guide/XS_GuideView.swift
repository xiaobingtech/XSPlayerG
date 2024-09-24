//
//  XS_GuideView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/22.
//

import SwiftUI
import SwiftData
import Alamofire

struct XS_GuideView: View {
    @Binding var isGuide: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var analyze: [XS_SDAnalyze]
    @Query private var iptv: [XS_SDIptv]
    @Query private var site: [XS_SDSite]
    @Query private var group: [XS_SDSiteGroup]
    @Query private var search: [XS_SDSiteSearch]
    
    var body: some View {
        upData()
        return _Content(isGuide: $isGuide)
    }
    
    private func upData() {
        guard search.isEmpty, let model = XS_ResourcesModel.rescources else { return }
        let searchItem = XS_SDSiteSearch()
        modelContext.insert(searchItem)
        do { // 影视
            try? modelContext.delete(model: XS_SDSiteGroup.self)
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
                if arr.count < 15  {
                    new.sort_search = arr.count - 1
                    new.search = searchItem
                }
            }
        }
        do { // 电视
            var arr: [String] = []
            for (index, item) in model.iptv.enumerated() {
                guard !item.url.isEmpty, !arr.contains(item.url) else { continue }
                arr.append(item.url)
                let new = XS_SDIptv(name: item.name, url: item.url, epg: item.epg, sort: index)
                modelContext.insert(new)
            }
        }
        do { // 解析
            var arr: [String] = []
            for (index, item) in model.analyze.enumerated() {
                guard !item.url.isEmpty, !arr.contains(item.url) else { continue }
                arr.append(item.url)
                let new = XS_SDAnalyze(name: item.name, url: item.url, sort: index)
                modelContext.insert(new)
            }
            for item in XS_SDAnalyzeCollect.list {
                modelContext.insert(item)
            }
        }
    }
}

private struct _Content: View {
    @Binding var isGuide: Bool
    @State private var num: Int = 0
    private var title: String {
        "3步完成配置" + (num > 0 ? "\(num)/3" : "")
    }
    var body: some View {
        ZStack {
            switch num {
            case 3: _Done(isGuide: $isGuide)
            case 2: _Search(num: $num)
            default: _Source(num: $num)
            }
        }
        .navigationTitle(title)
    }
}

private struct _Done: View {
    @Binding var isGuide: Bool
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Text("配置其他设置：").frame(maxWidth: .infinity, alignment: .leading)
            List {
                if isGuide {
                    Section {
                        XS_SetHot(text: "请选择热榜服务")
                    } header: {
                        Text("影视")
                    }
                }
                XS_SetGreen(text: "是否启用绿色模式")
            }
            Button {
                if isGuide {
                    isGuide = false
                } else {
                    dismiss()
                }
            } label: {
                Text("完  成")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 44)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

private struct _Search: View {
    @Binding var num: Int
    @Query private var search: [XS_SDSiteSearch]
    @Query(filter: #Predicate<XS_SDSiteGroup> { $0.isActive }, sort: \XS_SDSiteGroup.sort) private var data: [XS_SDSiteGroup]
    var body: some View {
        VStack {
            Text("配置搜索资源：").frame(maxWidth: .infinity, alignment: .leading)
            if let search = search.first {
                List(data, id: \.name) { item in
                    _SearchSection(search: search, name: item.name)
                }
            }
            Button {
                num = 3
            } label: {
                Text("下一步")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 44)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}
private struct _SearchSection: View {
    private let search: XS_SDSiteSearch
    private let name: String
    @Query(sort: \XS_SDSite.sort) private var data: [XS_SDSite]
    init(search: XS_SDSiteSearch, name: String) {
        self.search = search
        self.name = name
        let arr = search.sites.compactMap { $0.api }
        let predicate = #Predicate<XS_SDSite> { ($0.group?.name == name && $0.isActive) }
        _data = Query(filter: predicate, sort: \XS_SDSite.sort)
    }
    var body: some View {
        if !data.isEmpty {
            Section {
                ForEach(data, id: \.api) { item in
                    XS_SetSearchItem(item: item, search: search)
                }
            } header: {
                Text(name)
            }
        }
    }
}

private struct _Source: View {
    @Binding var num: Int
    @Query private var search: [XS_SDSiteSearch]
    @State private var isTest: Bool = false
    @State private var text: String = "开始检测"
    var body: some View {
        if !search.isEmpty {
            if isTest {
                _Test(num: $num)
            } else {
                Button(action: onTest) {
                    Text(text)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 200)
                        .background(.blue)
                        .clipShape(Circle())
                }
            }
        }
    }
    private func onTest() {
        let managera = NetworkReachabilityManager()
        managera?.startListening { status in
            managera?.stopListening()
            DispatchQueue.main.async {
                if status == .notReachable {
                    text = "网络故障\n请重试"
                } else {
                    isTest = true
                    num = 1
                }
            }
        }
    }
}
private struct _Test: View {
    @Binding var num: Int
    @State private var count: Int = 0
    var body: some View {
        VStack {
            if count > 0 {
                _TestSite(count: $count)
            }
            if count > 1 {
                _TestIptv(count: $count)
            }
            if count > 2 {
                _TestAnalyze(count: $count)
            }
        }
        .animation(.default, value: count)
        .frame(maxWidth: 200)
        .padding(.bottom, 100)
        .onAppear {
            guard count == 0 else { return }
            count += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                count += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                count += 1
            }
        }
        .onChange(of: count) { oldValue, newValue in
            guard newValue != oldValue, newValue == 6 else { return }
            DispatchQueue.main.async {
                num = 2
            }
        }
    }
}
private struct _TestSite: View {
    @Binding var count: Int
    @State private var total: Int = 0
    @State private var loadings: [String] = []
    @Query private var data: [XS_SDSiteGroup]
    private var text: String {
        total > 0 ? "\(total - loadings.count) / \(total) " : "- / - "
    }
    var body: some View {
        HStack {
            Text("影视:")
            Spacer()
            if loadings.isEmpty {
                Text("完成").foregroundStyle(.green)
            } else {
                Text(text)
                ProgressView()
            }
        }
        .frame(height: 50)
        .transition(.scale)
        .onAppear {
            guard total == 0 else { return }
            onTest()
        }
    }
    private func onTest() {
        if data.isEmpty {
            count += 1
            loadings.removeAll()
            return
        }
        let data = data
        var total: Int = 0
        for group in data {
            total += group.sites.count
            for item in group.sites {
                Task  {
                    let test: Bool
                    do {
                        test = try await XS_NetWork.shared.check(site: item.toSite)
                    } catch {
                        debugPrint(error.localizedDescription)
                        test = false
                    }
                    DispatchQueue.main.async {
                        item.test = test
                        item.isActive = test
                        if !test { item.search = nil }
                        loadings.removeLast()
                        if loadings.isEmpty {
                            count += 1
                        }
                    }
                }
            }
        }
        self.total = total
        loadings = .init(repeating: "", count: total)
    }
}
private struct _TestIptv: View {
    @Binding var count: Int
    @State private var total: Int = 0
    @State private var loadings: [String] = []
    @Query private var data: [XS_SDIptv]
    private var text: String {
        total > 0 ? "\(total - loadings.count) / \(total) " : "- / - "
    }
    var body: some View {
        HStack {
            Text("电视:")
            Spacer()
            if loadings.isEmpty {
                Text("完成").foregroundStyle(.green)
            } else {
                Text(text)
                ProgressView()
            }
        }
        .frame(height: 50)
        .transition(.scale)
        .onAppear {
            guard total == 0 else { return }
            onTest()
        }
    }
    private func onTest() {
        if data.isEmpty {
            count += 1
            loadings.removeAll()
            return
        }
        let data = data
        total = data.count
        loadings = .init(repeating: "", count: data.count)
        for item in data {
            Task  {
                let test: Bool
                do {
                    test = try await !XS_NetWork.shared.iptvList(item.url).isEmpty
                } catch {
                    debugPrint(error.localizedDescription)
                    test = false
                }
                DispatchQueue.main.async {
                    item.test = test
                    item.isActive = test
                    loadings.removeLast()
                    if loadings.isEmpty {
                        count += 1
                    }
                }
            }
        }
    }
}
private struct _TestAnalyze: View {
    @Binding var count: Int
    @State private var total: Int = 0
    @State private var loadings: [String] = []
    @Query private var data: [XS_SDAnalyze]
    private var text: String {
        total > 0 ? "\(total - loadings.count) / \(total) " : "- / - "
    }
    var body: some View {
        HStack {
            Text("解析:")
            Spacer()
            if loadings.isEmpty {
                Text("完成").foregroundStyle(.green)
            } else {
                Text(text)
                ProgressView()
            }
        }
        .frame(height: 50)
        .transition(.scale)
        .onAppear {
            guard total == 0 else { return }
            onTest()
        }
    }
    private func onTest() {
        if data.isEmpty {
            count += 1
            loadings.removeAll()
            return
        }
        let data = data
        total = data.count
        loadings = .init(repeating: "", count: data.count)
        for item in data {
            Task  {
                let test = await XS_NetWork.shared.check(url: item.url)
                DispatchQueue.main.async {
                    item.test = test
                    item.isActive = test
                    loadings.removeLast()
                    if loadings.isEmpty {
                        count += 1
                    }
                }
            }
        }
    }
}
