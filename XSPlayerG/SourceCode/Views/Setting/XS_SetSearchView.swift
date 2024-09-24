//
//  XS_SetSearchView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/20.
//

import SwiftUI
import SwiftData

struct XS_SetSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var search: [XS_SDSiteSearch]
    @Query(filter: #Predicate<XS_SDSiteGroup> { $0.isActive }, sort: \XS_SDSiteGroup.sort) private var data: [XS_SDSiteGroup]
    var body: some View {
        List {
            if let search = search.first {
                _Search(search: search)
                ForEach(data, id: \.name) { item in
                    _List(search: search, name: item.name)
                }
            }
        }
        .navigationTitle("影视搜索")
    }
}

private struct _Search: View {
    let search: XS_SDSiteSearch
    @Query(filter: #Predicate<XS_SDSite> { ($0.search != nil && $0.isActive) }, sort: \XS_SDSite.sort_search) private var data: [XS_SDSite]
    var body: some View {
        for (index, item) in data.enumerated() {
            if index != item.sort_search {
                item.sort_search = index
            }
        }
        return Section {
            ForEach(data, id: \.api) { item in
                XS_SetSearchItem(item: item, search: search)
            }
            .xs_move { from, to in
                data[from].sort_search = to
            }
        }
    }
}

private struct _List: View {
    private let search: XS_SDSiteSearch
    private let name: String
    @Query(sort: \XS_SDSite.sort) private var data: [XS_SDSite]
    init(search: XS_SDSiteSearch, name: String) {
        self.search = search
        self.name = name
        let arr = search.sites.compactMap { $0.api }
        let predicate = #Predicate<XS_SDSite> { ($0.group?.name == name && $0.isActive && !arr.contains($0.api)) }
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

struct XS_SetSearchItem: View {
    let item: XS_SDSite
    let search: XS_SDSiteSearch
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            let isSearch = item.search != nil
            Text(isSearch ? "已启用" : "未启用")
                .font(.footnote)
                .foregroundStyle(isSearch ? .green : .gray.opacity(0.5))
            Toggle("", isOn: .init(get: { isSearch }, set: { isOn in
                withAnimation {
                    if isOn {
                        item.sort_search = search.sites.count
                        item.search = search
                    } else {
                        item.search = nil
                    }
                }
            })).fixedSize()
        }
    }
}
