//
//  XS_IptvView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

struct XS_IptvView: View {
    @State private var tab: String = "Favorite" 
//    @SceneStorage("XS_IptvView._TabItem") private var tab: String = "Favorite"
    var body: some View {
        VStack(spacing: 0) {
            switch tab {
            case "Favorite": _Channel()
            case "IPTV": _Iptv()
            default: Spacer()
            }
            HStack {
                _TabItem(type: "Favorite", selection: $tab)
                Divider().padding(.vertical)
                _TabItem(type: "IPTV", selection: $tab)
            }
            .frame(height: 49)
            .padding(.horizontal)
        }
        .navigationTitle("电视·" + tab)
    }
}

private struct _TabItem: View {
    let type: String
    @Binding var selection: String
    var body: some View {
        Button {
            selection = type
        } label: {
            let isSelect = type == selection
            Text(type)
                .foregroundStyle(isSelect ? Color.accentColor : Color.gray.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct _Iptv: View {
    @Bindable private var store = XS_IptvReducer.store
    @SceneStorage("XS_IptvView._Iptv.Picker") private var api: String = ""
    @Query(filter: #Predicate<XS_SDIptv> { $0.isActive }, sort: \XS_SDIptv.sort) private var data: [XS_SDIptv]
    var body: some View {
        ZStack {
            let data = store.list
            List(data, id: \.title) { item in
                NavigationLink(item: .iptv(item)) {
                    Text(item.title)
                }
            }
            if store.isLoading {
                ProgressView()
            } else if data.isEmpty {
                Text("空")
            }
        }
        .onAppear {
            if api.isEmpty, let first = data.first {
                api = first.url
            }
            store.send(.onAppear(api))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("", selection: .init(get: { api }, set: {
                    api = $0
                    store.send(.setIptv($0))
                })) {
                    ForEach(data, id: \.url) { item in
                        Text(item.name).tag(item.url)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

private struct _Channel: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDChannel.sort) private var data: [XS_SDChannel]
    @State private var selection: XS_SDChannel?
    var body: some View {
        ZStack {
            let data = data
            _ToPlayer { obs in
                List {
                    ForEach(data, id: \.url) { item in
                        Button(item.name) {
                            obs.toPlay(item, list: data) { item in
                                selection = item
                            }
                        }
                        .foregroundStyle(item == selection ? .red : Color(uiColor: .label))
                    }
                    .xs_edit {
                        data.count
                    } delete: { index in
                        modelContext.delete(data[index])
                    } move: { from, to in
                        data[from].sort = to
                    }
                }
            }
            if data.isEmpty {
                Text("空")
            }
        }
    }
}
private struct _ToPlayer<Content: View>: View {
    let content: (_Obs) -> Content
    let obs: _Obs = .shared
    var body: some View {
        content(obs)
            .background {
                _ToPlayerRepresentable(obs: obs)
            }
    }
}
private struct _ToPlayerRepresentable: UIViewControllerRepresentable {
    var obs: _Obs
    func makeUIViewController(context: Context) -> UIViewController {
        obs.vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
private class _Obs: NSObject {
    static let shared = _Obs()
    lazy var vc = UIViewController()
    func toPlay(_ item: XS_SDChannel, list: [XS_SDChannel], selected: @escaping (XS_SDChannel) -> Void) {
        let player = XS_ChannelPlayer(item: item, list: list, selected: selected)
        vc.present(player, animated: true)
    }
}
