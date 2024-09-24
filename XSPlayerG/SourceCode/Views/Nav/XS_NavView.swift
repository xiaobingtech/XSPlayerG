//
//  XS_NavView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/5.
//

import SwiftUI
import ComposableArchitecture

struct XS_NavView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    @Bindable private var store = XS_NavReducer.store
    private let storeSplit = XS_SplitReducer.store
    var body: some View {
        NavigationStack(path: $store.path) {
            content()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            storeSplit.send(.setShow(true))
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
                .modifier(_NavDestination())
        }
    }
}

private struct _NavDestination: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationDestination(for: XS_NavReducer.State.XS_NavPathItem.self) { item in
            switch item {
            case let .detail(site, id, model):
                XS_DetailView(site: site, id: id, model: model)
            case let .site(value):
                XS_SiteView(site: value)
            case let .searchMore(site, text, models):
                XS_SearchMoreView(site: site, text: text, models: models)
            case let .iptv(value):
                XS_IptvListView(group: value)
            case .setJx:
                XS_JXResourcesView()
            case let .setJxEdit(value):
                XS_JXEditView(value)
            case .setIptv:
                XS_IptvResourcesView()
            case let .setIptvEdit(value):
                XS_IptvEditView(value)
            case .setSearch:
                XS_SetSearchView()
            case .setSiteGroup:
                XS_SiteGroupView()
            case let .setSite(value):
                XS_SiteResourcesView(name: value)
            case let .setSiteEdit(value):
                XS_SiteEditView(value)
            case .setOther:
                XS_SetOtherView()
            case let .siteChange(value):
                XS_SiteChangeView(text: value)
            case .setTest:
                XS_GuideView(isGuide: .constant(false))
            }
        }
    }
}
