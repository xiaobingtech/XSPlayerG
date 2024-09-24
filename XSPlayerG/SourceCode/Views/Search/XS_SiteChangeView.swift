//
//  XS_SiteChangeView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/21.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

struct XS_SiteChangeView: View {
    private let store: StoreOf<XS_SiteChangeReducer>
    @Query(filter: #Predicate<XS_SDSite> { $0.isActive && $0.search != nil }, sort: \XS_SDSite.sort_search) var data: [XS_SDSite]
    init(text: String) {
        store = XS_SiteChangeReducer.store(text: text)
    }
    var body: some View {
        _Content(store: store)
            .onAppear {
                guard store.lists.isEmpty else { return }
                store.send(.loadMore(data))
            }
    }
}

private struct _Content: View {
    let store: StoreOf<XS_SiteChangeReducer>
    var body: some View {
        _List(store: store)
            .navigationTitle(store.text)
            .toolbar {
                if !store.loading.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            ProgressView()
                            Text(store.loading)
                        }
                    }
                }
            }
    }
}

private struct _List: View {
    let store: StoreOf<XS_SiteChangeReducer>
    
    private var _data: [(XS_SDSite, [XS_VideoModel])] {
        store.sites.compactMap { site in
            guard let value = store.lists[site.api], !value.isEmpty else { return nil }
            return (site, value)
        }
    }
    var body: some View {
        ZStack {
            let data = _data
            List(data, id: \.0) { item in
                Section {
                    ForEach(item.1.prefix(3), id: \.self) { model in
                        NavigationLink(item: .detail(site: item.0.toSite, id: model.vod_id, model: model)) {
                            XS_SearchItem(item: model)
                        }
                    }
                } header: {
                    HStack(spacing: 0) {
                        Text(item.0.name)
                        Text(item.1.count < 10 ? " （\(item.1.count)）" : " （10+）")
                        Spacer()
                        if item.1.count > 3 {
                            NavigationLink(item: .searchMore(site: item.0.toSite, text: store.text, models: item.1)) {
                                Text("更多>>")
                            }
                        }
                    }
                }
            }
            if store.loading.isEmpty, data.isEmpty {
                Text("空")
            }
        }
    }
}
