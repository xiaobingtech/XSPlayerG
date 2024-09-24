//
//  XS_SearchView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/8.
//

import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI
import SwiftData

extension View {
    func xs_search(text: Binding<String>, isSearch: Binding<Bool>) -> ModifiedContent<Self, XS_SearchModifier> {
        modifier(XS_SearchModifier(text: text, isPresented: isSearch))
    }
}

struct XS_SearchModifier: ViewModifier {
    @Query(filter: #Predicate<XS_SDSite> { $0.isActive && $0.search != nil }, sort: \XS_SDSite.sort_search) private var siteData: [XS_SDSite]
    @Query private var searchData: [XS_SDSiteSearch]
    @Binding var text: String
    @Binding var isPresented: Bool
    private let store: StoreOf<XS_SearchReducer> = XS_SearchReducer.store
    func body(content: Content) -> some View {
        Group {
            if isPresented {
                _Content(store: store, text: $text)
            } else {
                content
            }
        }
        .searchable(text: $text, isPresented: $isPresented, prompt: "搜索关键字")
        .onSubmit(of: .search) {
            store.send(.search(text))
        }
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue == oldValue { return }
            if newValue {
                if !text.isEmpty {
                    store.send(.search(text))
                }
            } else {
                text = ""
                store.text = ""
                store.lists.removeAll()
                store.loading = ""
            }
        }
        .onAppear {
            store.send(.onAppear(searchData.first, siteData))
        }
    }
}
                            
//struct XS_SearchView: View {
//    private let store: StoreOf<XS_SearchReducer> = XS_SearchReducer.store
//    @State private var text: String
//    init(search: String?) {
//        if let search = search {
//            text = search
//            store.send(.search(search))
//        } else {
//            text = ""
//        }
//    }
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            if text.isEmpty {
//                _History(store: store, text: $text)
//            } else {
//                _List(store: store)
//            }
//            WithViewStore(store, observe: \.loading) { vs in
//                if !vs.isEmpty {
//                    HStack {
//                        ProgressView()
//                        Text(vs.state)
//                    }
//                    .foregroundStyle(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.black.opacity(0.3))
//                }
//            }
//        }
//        .searchable(text: $text, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索关键字")
//        .onSubmit(of: .search) {
//            store.send(.search(text))
//        }
//        .navigationTitle("搜索")
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                WithViewStore(store, observe: \.site) { vs in
//                    Picker("", selection: vs.binding) {
//                        WithViewStore(store, observe: \.all) { vs in
//                            ForEach(vs.state) { item in
//                                Text(item.name).tag(item)
//                            }
//                        }
//                    }
//                    .pickerStyle(.menu)
//                }
//            }
//        }
//    }
//}

private struct _Content: View {
    @Bindable var store: StoreOf<XS_SearchReducer>
    @Binding var text: String
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("资源:")
                Picker("", selection: $store.site.sending(\.setSite)) {
                    ForEach(store.all) { item in
                        Text(item.name).tag(item)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                if !store.loading.isEmpty {
                    HStack {
                        ProgressView()
                        Text(store.loading)
                    }
                }
            }
            .padding(.horizontal)
            if store.text.isEmpty {
                _History(store: store, text: $text)
            } else {
                _List(store: store)
            }
        }
    }
}

private struct _History: View {
    let store: StoreOf<XS_SearchReducer>
    @Binding var text: String
    var body: some View {
        XS_SearchHistoryView(data: store.search.history) { item in
            text = item
            store.send(.search(item))
        } onClear: {
            store.send(.clearHistory)
        }
    }
}
struct XS_SearchHistoryView: View {
    let data: [String]
    let onClick: (String) -> Void
    let onClear: () -> Void
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("搜索历史")
                        .foregroundStyle(.gray)
                    Spacer()
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(5)
                    }
                }
                ForEach(data, id: \.self) { item in
                    Button {
                        onClick(item)
                    } label: {
                        Text(item)
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(5)
                    }
                }
            }
            .padding()
        }
    }
}

private struct _List: View {
    let store: StoreOf<XS_SearchReducer>
    
    private var _data: [(XS_SDSite, [XS_VideoModel])] {
        store.current.compactMap { site in
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

struct XS_SearchItem: View {
    let item: XS_VideoModel
    var body: some View {
        HStack {
            VStack{
                Text(item.vod_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(item.xs_remark)
                    Spacer()
                    Text(item.xs_time)
                }
                .font(.footnote)
            }
            if !item.vod_pic.isEmpty {
                WebImage(url: URL(string: item.vod_pic))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .foregroundStyle(Color(uiColor: .label))
    }
}
