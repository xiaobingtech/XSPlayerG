//
//  XS_SiteResourcesView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/20.
//

import SwiftUI
import SwiftData

struct XS_SiteGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDSiteGroup.sort) private var data: [XS_SDSiteGroup]
    @State private var loadings: [String:[String]] = [:]
    var body: some View {
        List {
            ForEach(data, id: \.name) { item in
                NavigationLink(item: .setSite(item.name)) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        HStack(spacing: 0) {
                            if loadings[item.name] == nil {
                                let count = item.sites.filter({ $0.isActive }).count
                                Text("\(count)")
                            } else {
                                ProgressView()
                            }
                            Text(" / \(item.sites.count)")
                        }
                        Toggle("", isOn: .init(get: { item.isActive }, set: { item.isActive = $0 }))
                            .fixedSize()
                    }
                }
            }
            .xs_edit {
                data.count
            } delete: { index in
                modelContext.delete(data[index])
            } move: { from, to in
                data[from].sort = to
            }
        }
        .navigationTitle("影视资源分组")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if loadings.isEmpty {
                    Button("检测", action: onTest)
                } else {
                    ProgressView()
                }
                NavigationLink(item: .setSiteEdit(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func onTest() {
        if data.isEmpty {
            loadings.removeAll()
            return
        }
        let data = data
        for group in data {
            loadings[group.name] = .init(repeating: "", count: group.sites.count)
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
                        if var arr = loadings[group.name] {
                            arr.removeLast()
                            loadings[group.name] = arr.isEmpty ? nil : arr
                        }
                    }
                }
            }
        }
    }
}
struct XS_SiteResourcesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDSite.sort) private var data: [XS_SDSite]
    @State private var loadings: [String] = []
    private let name: String
    init(name: String) {
        self.name = name
        _data = Query(filter: #Predicate<XS_SDSite> { $0.group?.name == name }, sort: \XS_SDSite.sort)
    }
    var body: some View {
        List {
            ForEach(data, id: \.api) { item in
                NavigationLink(item: .setSiteEdit(item)) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        if let test = item.test {
                            Text(test ? "有效" : "失效")
                                .font(.footnote)
                                .foregroundStyle(test ? .green : .red)
                        }
                        Toggle("", isOn: .init(get: { item.isActive }, set: { item.isActive = $0 }))
                            .fixedSize()
                    }
                }
            }
            .xs_edit {
                data.count
            } delete: { index in
                modelContext.delete(data[index])
            } move: { from, to in
                data[from].sort = to
            }
        }
        .navigationTitle(name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if loadings.isEmpty {
                    Button("检测", action: onTest)
                } else {
                    ProgressView()
                }
                NavigationLink(item: .setSiteEdit(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func onTest() {
        if data.isEmpty { return }
        let data = data
        loadings = .init(repeating: "", count: data.count)
        for item in data {
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
                }
            }
        }
    }
}
