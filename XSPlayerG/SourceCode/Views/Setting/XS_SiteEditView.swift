//
//  XS_SiteEditView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/20.
//

import SwiftUI
import SwiftData

struct XS_SiteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var searchData: [XS_SDSiteSearch]
    @Query private var groupData: [XS_SDSiteGroup]
    @Query private var data: [XS_SDSite]
    private let item: XS_SDSite?
    
    @State private var name: String
    @State private var api: String
    @State private var type: XS_SDSite._Type?
    @State private var playUrl: String
    @State private var download: String
    @State private var group: XS_SDSiteGroup?
    @State private var search: Bool
    
    @State private var test: Bool?
    @State private var isLoading: Bool = false

    init(_ item: XS_SDSite?) {
        self.item = item
        if let item = item {
            _name = .init(wrappedValue: item.name)
            _api = .init(wrappedValue: item.api)
            _playUrl = .init(wrappedValue: item.playUrl)
            _download = .init(wrappedValue: item.download)
            _search = .init(wrappedValue: item.search != nil)
            _type = .init(wrappedValue: item.type)
            _group = .init(wrappedValue: item.group)
            _test = .init(wrappedValue: item.test)
        } else {
            _name = .init(wrappedValue: "")
            _api = .init(wrappedValue: "")
            _playUrl = .init(wrappedValue: "")
            _download = .init(wrappedValue: "")
            _search = .init(wrappedValue: false)
        }
    }
    private func onChange<T: Equatable>(_ oldValue: T, _ newValue: T) {
        if newValue == oldValue { return }
        test = nil
        isLoading = false
    }
    private func onTest() {
        guard !api.isEmpty, type != nil else { return }
        let api = api
        let type = type
        isLoading = true
        Task  {
            let test: Bool
            do {
                test = try await XS_NetWork.shared.check(site: .init(name: "", api: api, playUrl: "", type: type))
            } catch {
                debugPrint(error.localizedDescription)
                test = false
            }
            if api == self.api, type == self.type {
                DispatchQueue.main.async {
                    self.test = test
                    if let item = item, item.api == api, item.type == type {
                        item.test = test
                        item.isActive = test
                        if !test { item.search = nil }
                    }
                    isLoading = false
                }
            }
        }
    }
    private func onSave() {
        guard !name.isEmpty, !api.isEmpty else { return }
        if data.contains(where: { $0.api == api && $0 != item }) {
            api = "链接重复！！！"
            return
        }
        let g: XS_SDSiteGroup
        if let group = group {
            g = group
        } else if let group = groupData.first(where: { $0.name == "未分组" }) {
            g = group
        } else {
            let new = XS_SDSiteGroup(name: "未分组", sort: groupData.count)
            g = new
            modelContext.insert(new)
        }
        if let item = item {
            item.name = name
            item.api = api
            item.download = download
            item.playUrl = playUrl
            item.type = type
            item.search = search ? searchData.first : nil
            item.group = g
            item.test = test
        } else {
            let new = XS_SDSite(name: name, api: api, download: download, playUrl: playUrl, type: type, sort: g.sites.count)
            modelContext.insert(new)
            new.test = test
            new.search = search ? searchData.first : nil
            new.group = g
        }
        dismiss()
    }
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                HStack {
                    Text("链接状态：")
                    if isLoading {
                        ProgressView()
                    } else {
                        switch test {
                        case true: Text("有效").foregroundStyle(.green)
                        case false: Text("失效").foregroundStyle(.red)
                        default: Text("未检测")
                        }
                    }
                }
                Group {
                    _Text(name: "name:", hold: "名称", text: $name)
                    _Text(name: "api:", hold: "链接", text: $api).onChange(of: api, onChange)
                    _Type(type: $type).onChange(of: type, onChange)
                    _Group(group: $group)
                    _Text(name: "analyze（非必填）:", hold: "解析链接", text: $playUrl)
                    _Text(name: "download（未启用）:", hold: "下载链接", text: $download)
                    _Search(search: $search)
                }
                
                    
            }
            .padding()
        }
        .navigationTitle(item == nil ? "新增影视资源" : "编辑影视资源")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("检测", action: onTest)
                }
                Button("保存", action: onSave)
            }
        }
    }
}

private struct _Text: View {
    let name: String
    let hold: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.footnote)
            TextField(hold, text: $text)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
        }
    }
}
private struct _Type: View {
    @Binding var type: XS_SDSite._Type?
    var body: some View {
        HStack {
            Text("type:").font(.footnote)
            Picker("", selection: .init(get: { type?.rawValue ?? -1 }, set: { type = .init(rawValue: $0) })) {
                ForEach(XS_SDSite._Type.allCases, id: \.self) { item in
                    Text(item.name).tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
private struct _Group: View {
    @Binding var group: XS_SDSiteGroup?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDSiteGroup.sort) private var groupData: [XS_SDSiteGroup]
    @State private var isChoose: Bool = true
    @State private var text: String = ""
    var body: some View {
        HStack {
            Text("group:").font(.footnote)
            if isChoose {
                Picker("", selection: .init(get: { group ?? .init(name: "", sort: 0) }, set: { group = $0 })) {
                    ForEach(groupData, id: \.name) { item in
                        Text(item.name).tag(item)
                    }
                }
                .pickerStyle(.menu)
                Button {
                    isChoose = false
                } label: {
                    Image(systemName: "plus.circle").padding(10)
                }
            } else {
                TextField("分组名称", text: $text)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let name = text
                    if let item = groupData.first(where: { $0.name == name }) {
                        group = item
                    } else {
                        let new = XS_SDSiteGroup(name: name, sort: groupData.count)
                        modelContext.insert(new)
                        group = new
                    }
                    isChoose = true
                } label: {
                    Image(systemName: "checkmark.circle").padding(10)
                        .foregroundStyle(.green)
                }
                Button {
                    isChoose = true
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle").padding(10)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
private struct _Search: View {
    @Binding var search: Bool
    var body: some View {
        HStack {
            Text("是否加入到搜索组：")
            Spacer()
            Toggle("", isOn: $search)
                .fixedSize()
        }
    }
}
