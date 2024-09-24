//
//  XS_IptvEditView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/19.
//

import SwiftUI
import SwiftData

struct XS_IptvEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDIptv.sort) private var data: [XS_SDIptv]
    private let item: XS_SDIptv?
    @State private var name: String
    @State private var url: String
    @State private var epg: String
    @State private var isSave: Bool = true
    @State private var save: XS_SDIptv?
    @State private var test: Bool?
    @State private var isLoading: Bool = false
    init(_ item: XS_SDIptv?) {
        self.item = item
        if let item = item {
            _name = .init(wrappedValue: item.name)
            _url = .init(wrappedValue: item.url)
            _epg = .init(wrappedValue: item.epg)
            _test = .init(wrappedValue: item.test)
        } else {
            _name = .init(wrappedValue: "")
            _url = .init(wrappedValue: "")
            _epg = .init(wrappedValue: "")
        }
    }
    private func onTest() {
        if url.isEmpty { return }
        let url = url
        isLoading = true
        Task  {
            let test: Bool
            do {
                test = try await !XS_NetWork.shared.iptvList(url).isEmpty
            } catch {
                debugPrint(error.localizedDescription)
                test = false
            }
            if url == self.url {
                DispatchQueue.main.async {
                    self.test = test
                    if let item = item, item.url == url {
                        item.test = test
                        item.isActive = test
                    }
                    isLoading = false
                }
            }
        }
    }
    private func onSave() {
        guard !url.isEmpty, !name.isEmpty else { return }
        if isSave, url != item?.url, let index = data.firstIndex(where: { $0.url == url }) {
            save = data[index]
            isSave = false
            return
        }
        let sort: Int
        if let save = save {
            modelContext.delete(save)
            sort = save.sort
        } else {
            sort = data.count
        }
        if let item = item {
            item.url = url
            item.name = name
            item.test = test
        } else {
            let new = XS_SDIptv(name: name, url: url, epg: epg, sort: sort)
            modelContext.insert(new)
            new.test = test
        }
        dismiss()
    }
    var body: some View {
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
            if isSave {
                Text("name:").font(.footnote)
                TextField("名称", text: $name)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                Text("url:").font(.footnote)
                TextField("链接", text: $url)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: url) { oldValue, newValue in
                        if newValue == oldValue { return }
                        test = nil
                        isLoading = false
                    }
                Text("epg节目单（字段未启用）:").font(.footnote)
                TextField("节目单", text: $epg)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text("此链接已存在，确认是否进行覆盖").font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                if let save = save {
                    Text("新:\n\(name)\n\(url)\n\(epg)\n\n旧:\n\(save.name)\n\(save.url)\n\(save.epg)")
                        .fixedSize()
                }
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle(item == nil ? "新增电视资源" : "编辑电视资源")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("检测", action: onTest)
                }
                Button(isSave ? "保存" : "确认", action: onSave)
            }
        }
    }
}
