//
//  XS_SiteSearchView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/22.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

struct XS_SiteSearchView: View {
    @Query private var searchData: [XS_SDSiteSearch]
    let store: StoreOf<XS_SiteSearchReducer>
    var body: some View {
        ZStack {
            if store.current.isEmpty {
                XS_SearchHistoryView(data: store.search?.history ?? []) { item in
                    store.text = item
                    store.send(.search)
                } onClear: {
                    store.search?.history.removeAll()
                }
            } else {
                _List(store: store)
            }
        }
        .onAppear {
            if let search = searchData.first {
                store.search = search
            }
        }
    }
}

private struct _List: View {
    let store: StoreOf<XS_SiteSearchReducer>
    
    var body: some View {
        ZStack {
            let data = store.list
            List {
                Section {
                    ForEach(data.prefix(10), id: \.self) { model in
                        NavigationLink(item: .detail(site: store.site, id: model.vod_id, model: model)) {
                            XS_SearchItem(item: model)
                        }
                    }
                } header: {
                    HStack(spacing: 0) {
                        Text(store.site.name)
                        if store.isLoading {
                            Spacer()
                            ProgressView()
                        } else {
                            Text(data.count < 10 ? " （\(data.count)）" : " （10+）")
                            Spacer()
                            if data.count > 10 {
                                NavigationLink(item: .searchMore(site: store.site, text: store.current, models: data)) {
                                    Text("更多>>")
                                }
                            }
                        }
                    }
                }
            }
            if !store.isLoading, data.isEmpty {
                Text("空")
            }
        }
    }
}
