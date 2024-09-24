//
//  XS_SearchMoreView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/9.
//

import SwiftUI
import ComposableArchitecture

struct XS_SearchMoreView: View {
    private let store: StoreOf<XS_SearchMoreReducer>
    private let text: String
    private let site: XS_SiteM
    init(site: XS_SiteM, text: String, models: [XS_VideoModel]) {
        self.text = text
        self.site = site
        store = XS_SearchMoreReducer.store(site: site, text: text, models: models)
    }
    var body: some View {
        List {
            Section {
                ForEach(store.list) { item in
                    NavigationLink(item: .detail(site: site, id: item.vod_id, model: item)) {
                        XS_SearchItem(item: item)
                    }
                }
            } header: {
                Text(site.name)
            } footer: {
                XS_LoadingView(item: store.loading)
                    .onAppear {
                        store.send(.loadMore)
                    }
            }
        }
        .navigationTitle(text)
    }
}
