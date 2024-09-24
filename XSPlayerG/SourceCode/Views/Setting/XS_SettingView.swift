//
//  XS_SettingView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/18.
//

import SwiftUI
import SwiftData

struct XS_SettingView: View {
    @Query(sort: \XS_SDAnalyze.sort) private var analyze: [XS_SDAnalyze]
    var body: some View {
        List {
            Section {
                NavigationLink(item: .setSiteGroup) {
                    Text("影视资源")
                }
                NavigationLink(item: .setSearch) {
                    Text("影视搜索")
                }
                XS_SetHot(text: "影视热榜")
            } header: {
                Text("影视")
            }
            Section {
                NavigationLink(item: .setIptv) {
                    Text("电视资源")
                }
            } header: {
                Text("电视")
            }
            Section {
                NavigationLink(item: .setJx) {
                    Text("解析资源")
                }
            } header: {
                Text("解析")
            }
            Section {
                NavigationLink(item: .setOther) {
                    Text("其他设置")
                }
            } header: {
                Text("其他")
            }
        }
        .navigationTitle("设置")
    }
}

struct XS_SetHot: View {
    let text: String
    @Query private var searchData: [XS_SDSiteSearch]
    @Query(filter: #Predicate<XS_SDSite> { ($0.search != nil && $0.isActive) }, sort: \XS_SDSite.sort_search) private var data: [XS_SDSite]
    var body: some View {
        if !searchData.isEmpty {
            Picker(text, selection: .init(get: getSelection, set: setSelection)) {
                Text("    第三方：")
                    .font(.footnote)
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.top)
                ForEach(XS_SDSiteSearch._HotType.allCases, id: \.self) { item in
                    Text(item.rawValue).tag(_SelectionType.type(item))
                }
                Text("    Site资源：")
                    .font(.footnote)
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.top)
                ForEach(data, id: \.api) { item in
                    Text(item.name).tag(_SelectionType.site(item.toSite))
                }
            }
            .pickerStyle(.navigationLink)
        }
    }
    private func getSelection() -> _SelectionType {
        guard let search = searchData.first else { return .none }
        if let type = search.hot {
            return .type(type)
        } else {
            return .site(search.toSite)
        }
    }
    private func setSelection(_ type: _SelectionType) {
        guard let search = searchData.first else { return }
        switch type {
        case let .type(hot):
            search.hot = hot
        case let .site(site):
            search.hot_name = site.name
            search.hot_api = site.api
            search.hot_type = site.type
            search.hot = nil
        case .none: break
        }
    }
    private enum _SelectionType: Hashable {
        case type(XS_SDSiteSearch._HotType)
        case site(XS_SiteM)
        case none
    }
}
