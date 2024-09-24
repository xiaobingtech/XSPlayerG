//
//  XS_FilmView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/5.
//

import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI
import SwiftData

struct XS_FilmView: View {
    @Bindable private var store = XS_FilmReducer.store
    @State private var search: String = ""
    @State private var isSearch: Bool = false
//    @SceneStorage("XS_FilmView.XS_TabType") var tab: XS_TabType = .收藏
    var body: some View {
        VStack(spacing: 0) {
            switch store.tab {
            case .收藏: _Collect()
            case .历史: _History()
            case .热门: _Hot(store: store, search: $search, isSearch: $isSearch)
            case .资源: _Source()
            }
            HStack {
                _TabItem(type: .收藏, img: "star", selection: $store.tab)
                Divider().padding(.vertical)
                _TabItem(type: .历史, img: "clock", selection: $store.tab)
                Divider().padding(.vertical)
                _TabItem(type: .热门, img: "flame", selection: $store.tab)
                Divider().padding(.vertical)
                _TabItem(type: .资源, img: "film", selection: $store.tab)
            }
            .frame(height: 49)
            .padding(.horizontal)
        }
        .xs_search(text: $search, isSearch: $isSearch)
    }
}
private struct _Collect: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDSiteCollect.sort) private var data: [XS_SDSiteCollect]
    @State private var isFirst: Bool = true
    var body: some View {
        ZStack {
            List {
                ForEach(data, id: \.self) { item in
                    NavigationLink(item: .detail(site: item.toSite, id: item.vod_id, model: nil)) {
                        _CollectItem(item: item)
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
            if data.isEmpty {
                Text("空")
            }
        }
        .navigationTitle("收藏")
        .task {
            guard isFirst else { return }
            isFirst = false
            let data = data
            for item in data {
                Task {
                    do {
                        if let model = try await XS_NetWork.shared.detail(site: item.toSite, id: item.vod_id).first {
                            item.vod_name = model.vod_name
                            item.vod_remark = model.xs_remark
                            item.vod_pic = model.vod_pic
                        }
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
            }
        }
    }
}
private struct _CollectItem: View {
    let item: XS_SDSiteCollect
    var body: some View {
        HStack {
            VStack{
                Text(item.vod_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(item.vod_remark)
                    Spacer()
                    Text(item.name)
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

private struct _History: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDSiteHistory.date, order: .reverse) private var data: [XS_SDSiteHistory]
    var body: some View {
        ZStack {
            let data = data.filter { $0.vod_type.is18 }
            List {
                ForEach(data, id: \.self) { item in
                    NavigationLink(item: .detail(site: item.toSite, id: item.vod_id, model: nil)) {
                        _HistoryItem(item: item)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        modelContext.delete(data[index])
                    }
                }
            }
            if data.isEmpty {
                Text("空")
            }
        }
        .navigationTitle("观看历史")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    try? modelContext.delete(model: XS_SDSiteHistory.self)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}
private struct _HistoryItem: View {
    let item: XS_SDSiteHistory
    var body: some View {
        VStack{
            HStack {
                Text(item.vod_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.date.xs_time)
                    .font(.footnote)
            }
            HStack {
                if let text = item.url_name {
                    Text(text)
                }
                Spacer()
                Text(item.name)
            }
            .font(.footnote)
        }
        .foregroundStyle(Color(uiColor: .label))
    }
}

private struct _Hot: View {
    @Query private var searchData: [XS_SDSiteSearch]
    @Bindable var store: StoreOf<XS_FilmReducer>
    @Binding var search: String
    @Binding var isSearch: Bool
    var body: some View {
        ZStack {
            List(0..<store.hotList.count, id: \.self) { index in
                let item = store.hotList[index]
                Button {
                    search = item.vod_name
                    isSearch = true
                } label: {
                    _HotItem(index: index, item: item)
                }
            }
            .refreshable {
                await store.send(.upHot).finish()
            }
            if store.hotList.isEmpty {
                Text("空")
            }
        }
        .onAppear {
            store.send(.onAppear(searchData.first))
        }
        .navigationTitle("热门·" + (store.search?.hot_title ?? ""))
        .toolbar {
            if searchData.first?.hot == .云合 {
                ToolbarItem(placement: .topBarTrailing) {
                    _HotPicker(store: store)
                }
            }
        }
    }
}
private struct _HotPicker: View {
    let store: StoreOf<XS_FilmReducer>
    var body: some View {
        Picker("", selection: .init(get: { store.enlightentHotType }, set: { store.send(.setType($0)) })) {
            ForEach(XS_NetWork.XS_EnlightentHotType.allCases, id: \.self) { item in
                Text(item.name).tag(item)
            }
        }
        .pickerStyle(.menu)
    }
}
private struct _HotItem: View {
    let index: Int
    let item: XS_VideoModel
    var body: some View {
        HStack {
            Text(String(format: "%.2d", index+1))
                .font(.title)
                .fontDesign(.monospaced)
                .foregroundStyle(.red)
            VStack(alignment: .leading) {
                Text(item.vod_name)
                let text = item.xs_hot
                if !text.isEmpty {
                    Text(text)
                        .font(.footnote)
                }
            }
            .foregroundStyle(Color(uiColor: .label))
            .frame(maxWidth: .infinity, alignment: .leading)
            if !item.vod_pic.isEmpty {
                WebImage(url: URL(string: item.vod_pic))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

private struct _Source: View {
    @Query(filter: #Predicate<XS_SDSiteGroup> { $0.isActive }, sort: \XS_SDSiteGroup.sort) private var data: [XS_SDSiteGroup]
    var body: some View {
        List {
            let data = data.filter { $0.name.is18 }
            ForEach(data, id: \.name) { item in
                _SourceSection(name: item.name)
            }
        }
        .navigationTitle("资源")
    }
}
private struct _SourceSection: View {
    private let name: String
    @Query(sort: \XS_SDSite.sort) private var data: [XS_SDSite]
    init(name: String) {
        self.name = name
        _data = Query(filter: #Predicate<XS_SDSite> { $0.isActive && $0.group?.name == name }, sort: \XS_SDSite.sort)
    }
    var body: some View {
        if !data.isEmpty {
            Section {
                ForEach(data, id: \.api) { item in
                    NavigationLink(item: .site(site: item.toSite)) {
                        Text(item.name)
                    }
                }
            } header: {
                Text(name)
            }
        }
    }
}

private struct _TabItem: View {
    let type: XS_FilmReducer.State.XS_TabType
    let img: String
    @Binding var selection: XS_FilmReducer.State.XS_TabType
    var body: some View {
        Button {
            selection = type
        } label: {
            let isSelect = type == selection
            Label(type.rawValue, systemImage: isSelect ? img + ".fill" : img)
                .foregroundStyle(isSelect ? Color.accentColor : Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
