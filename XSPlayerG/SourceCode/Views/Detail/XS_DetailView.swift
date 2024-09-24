//
//  XS_DetailView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/29.
//

import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI
import SwiftData

struct XS_DetailView: View {
    let site: XS_SiteM
    let id: String
    let model: XS_VideoModel?
    private let store: StoreOf<XS_DetailReducer> = XS_DetailReducer.store
    var body: some View {
        _Content(site: site, store: store)
            .onAppear {
                store.send(.onAppear(site, id, model))
            }
    }
}

private struct _Content: View {
    @State private var contentH: Double = 0
    @State private var actorH: Double = 0
    @State private var opacity: CGFloat = 0.1
    let site: XS_SiteM
    let store: StoreOf<XS_DetailReducer>
    var body: some View {
        ZStack(alignment: .top) {
            if let model = store.model {
                WebImage(url: URL(string: model.vod_pic))
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .opacity(opacity)
                ScrollView {
                    VStack {
                        let h = UIScreen.main.bounds.height/6
                        GeometryReader { proxy in
                            Color.clear
                                .frame(height: 80)
                                .onChange(of: proxy.frame(in: .named("detailZTop")).minY) { oldValue, newValue in
                                    opacity = 0.1 + newValue/h
                                }
                        }
                        VStack {
                            VStack {
                                _EmptyText(text: model.xs_tags, title: nil)
                                _EmptyText(text: model.vod_director, title: "导演")
//                                _EmptyText(text: model.vod_actor, title: "演员")
                                if !model.vod_actor.isEmpty {
                                    _Introduction(text: "演员: " + model.vod_actor, height: $actorH)
                                }
                                _Introduction(text: model.xs_content, height: $contentH)
                                    .padding(.vertical, 5)
                            }
                            .padding(.horizontal)
                            _Douban(store: store, site: site)
                            let fullList = model.fullList
                            if !fullList.isEmpty {
                                _Tab(site: site, model: model, fullList: fullList, keys: Array(fullList.keys.sorted()))
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .animation(.default, value: contentH + actorH)
                        .opacity(1.1 - opacity)
                    }
                }
                .navigationTitle(opacity > 0.5 ? "" : model.vod_name)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink(item: .siteChange(model.vod_name)) {
                            Text("换源")
                        }
                        _Collect(site: site, model: model)
                    }
                }
            }
        }
        .coordinateSpace(.named("detailZTop"))
    }
}
private struct _Collect: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var data: [XS_SDSiteCollect]
    let site: XS_SiteM
    let model: XS_VideoModel
    init(site: XS_SiteM, model: XS_VideoModel) {
        self.site = site
        self.model = model
    }
    var body: some View {
        let item = data.first { $0.api == site.api && $0.vod_id == model.vod_id }
        return Button {
            if let item = item {
                modelContext.delete(item)
            } else {
                let new = XS_SDSiteCollect(site: site, model: model, sort: data.count)
                modelContext.insert(new)
            }
        } label: {
            Image(systemName: item == nil ? "star" : "star.fill")
        }
    }
}

private struct _EmptyText: View {
    let text: String
    let title: String?
    private var str: String {
        if let title = title {
            return title + ": " + text
        } else {
            return text
        }
    }
    var body: some View {
        if !text.isEmpty {
            Text(str)
        }
    }
}

private struct _Introduction: View {
    let text: String
    @Binding var height: Double
    @State private var longH: Double = 11
    @State private var shortH: Double = 10
    var body: some View {
        if !text.isEmpty {
            if longH > shortH {
                let isShow = height == longH
                ZStack(alignment: .bottomTrailing) {
                    ZStack(alignment: .topLeading) {
                        _TextLayout(height: $longH) {
                            Text(text)
                                .opacity(isShow ? 1 : 0)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        _TextLayout(height: $shortH) {
                            Text(text)
                                .lineLimit(2)
                                .opacity(isShow ? 0 : 1)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(height: isShow ? longH : shortH, alignment: .top)
                    .clipped()
                    if !isShow {
                        Text("展开更多")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                            .padding(3)
                            .background()
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .offset(y: 3)
                    }
                }
                .onTapGesture {
                    height = isShow ? shortH : longH
                }
            } else {
                Text(text)
            }
        }
    }
}
private struct _TextLayout: Layout {
    @Binding var height: Double
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let view = subviews.first else { return .zero }
        let size = view.sizeThatFits(proposal)
        DispatchQueue.main.async {
            height = size.height
        }
        return size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let view = subviews.first else { return }
        view.place(at: bounds.origin, anchor: .topLeading, proposal: proposal)
    }
}

private struct _Douban: View {
    let store: StoreOf<XS_DetailReducer>
    let site: XS_SiteM
    var body: some View {
        if let score = store.score {
            HStack {
                Group {
                    if score.isEmpty {
                        Text("暂无\n评分")
                            .font(.system(size: 20))
                    } else {
                        VStack {
                            Text(score)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("评分")
                                .font(.system(size: 10))
                        }
                    }
                }
                .frame(width: 60)
                _Recommend(store: store, site: site)
            }
        }
    }
}
private struct _Recommend: View {
    let store: StoreOf<XS_DetailReducer>
    let site: XS_SiteM
    var body: some View {
        HStack(spacing: 0) {
            Divider()
            Text("相\n关\n推\n荐")
                .font(.system(size: 10))
                .fixedSize()
                .padding(5)
                .background()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(width: 0)
                .zIndex(10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                    ForEach(store.recommend, id: \.name) { item in
                        NavigationLink(item: .searchMore(site: site, text: item.name, models: [])) {
                            _RecommendItem(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
private struct _RecommendItem: View {
    let item: XS_DoubanRecommendModel
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                WebImage(url: URL(string: item.img))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 123)
                if !item.score.isEmpty {
                    Text(item.score)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .padding(.horizontal, 5)
                        .background(Color("Gold"))
                        .clipShape(.rect(cornerRadii: .init(bottomTrailing: 5)))
                }
            }
            .clipped()
            Text(item.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(width: 92, alignment: .leading)
        }
        .padding(.bottom, 3)
        .background()
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .foregroundColor(Color(uiColor: .label))
    }
}

private struct _Tab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var history: [XS_SDSiteHistory]
    @State private var selection: Int = 0
    @State private var sort: Bool = true
    @State private var page: Int = 0
    @State private var url: String = ""
    let site: XS_SiteM
    let model: XS_VideoModel
    let fullList: [String:[String]]
    let keys: [String]
    private let store = XS_FilmReducer.store
    @State private var isPlay: Bool = false
    init(site: XS_SiteM, model: XS_VideoModel, fullList: [String : [String]], keys: [String]) {
        self.site = site
        self.model = model
        self.fullList = fullList
        self.keys = keys
        let api = site.api
        let id = model.vod_id
        _history = Query(filter: #Predicate<XS_SDSiteHistory> { $0.api == api && $0.vod_id == id })
    }
    private func getData(_ sortData: [String]) -> [String] {
        if sortData.count > 30 {
            let start = page*30
            let end = min(start + 30, sortData.count)
            return Array(sortData[start..<end])
        } else {
            return sortData
        }
    }
    var body: some View {
        VStack(alignment: .leading) {
            _Yuan(
                keys: keys,
                selection: .init(
                    get: { selection },
                    set: { value in
                        selection = value
                        guard !url.isEmpty, let name = url.split(separator: "$").first, let data = fullList[keys[value]] else { return }
                        url = data.first {
                            $0.split(separator: "$").first == name
                        } ?? ""
                    }
                ),
                sort: $sort
            )
            let data = fullList[keys[selection]] ?? []
            let sortData = sort ? data : data.reversed()
            Divider()
                .onAppear {
                    if isPlay {
                        isPlay = false
                        if let item = history.first {
                            item.playUrl = site.playUrl
                            item.type = site.type
                            item.selection = selection
                            item.url = url
                            item.sort = sort
                            item.date = Date()
                        } else {
                            let all: [XS_SDSiteHistory] = Query(sort: \XS_SDSiteHistory.date).wrappedValue
                            if all.count >= 30, let item = all.first {
                                modelContext.delete(item)
                            }
                            let new = XS_SDSiteHistory(site: site, model: model, sort: sort, selection: selection, url: url)
                            modelContext.insert(new)
                        }
                    } else if let item = history.first {
                        selection = item.selection
                        url = item.url
                        sort = item.sort
                    }
                    if !url.isEmpty, let index = sortData.firstIndex(of: url) {
                        page = index/30
                    }
                }
            if sortData.count > 30 {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0...sortData.count/30, id: \.self) { index in
                            Button {
                                page = index
                            } label: {
                                Text("\(index + 1)")
                                    .padding()
                            }
                            .foregroundColor(index == page ? .red : Color(uiColor: .label))
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            _ToPlayer { obs in
                _ListLayout(itemHeight: 30) {
                    let pageData = getData(sortData)
                    ForEach(pageData, id: \.self) { item in
                        let select = (item == url)
                        let name = item.split(separator: "$").first ?? "--"
                        Button {
                            url = item
                            obs.toPlay(site, model: model, list: sortData, item: item) { item in
                                url = item
                                isPlay = true
                            }
                        } label: {
                            Text(name)
                                .padding(.horizontal, 8)
                                .frame(height: 30)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5).stroke()
                                }
                                .foregroundColor(select ? .white : .accentColor)
                                .background(select ? Color.accentColor : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }
        }
    }
}

private struct _Yuan: View {
    let keys: [String]
    @Binding var selection: Int
    @Binding var sort: Bool
    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(0..<keys.count, id: \.self) { index in
                        Button {
                            selection = index
                        } label: {
                            Text(keys[index])
                                .padding(.horizontal)
                                .frame(height: 30)
                                .overlay {
                                    Capsule().stroke()
                                }
                        }
                        .foregroundColor(index == selection ? .red : nil)
                    }
                }
                .padding(3)
            }
            Divider()
            Button {
                sort.toggle()
            } label: {
                Image(systemName: "arrow.up.and.down.text.horizontal")
            }
        }
    }
}

private struct _ListLayout: Layout {
    let itemHeight: Double
    private let dict = NSMutableDictionary()
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty, let width = proposal.width else {
            return .zero
        }
        return size(boundsWidth: width, subviews: subviews)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty, let arr = dict["\(Int(bounds.width))"] as? [CGPoint], subviews.count == arr.count else {
            return
        }
        for index in subviews.indices {
            let point = arr[index]
            subviews[index].place(
                at: CGPoint(x: point.x, y: point.y + bounds.minY),
                anchor: .leading,
                proposal: .unspecified
            )
        }
    }
    private func size(boundsWidth: Double, subviews: Subviews) -> CGSize {
        let spacing: Double = 10
        var point: CGPoint = CGPoint(x: spacing, y: 0)
        var arr: [CGPoint] = []
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if point.x + size.width + spacing > boundsWidth {
                point.x = spacing
                point.y += (spacing + itemHeight)
            }
            arr.append(CGPoint(x: point.x, y: point.y + itemHeight/2))
            point.x += (size.width + spacing)
        }
        dict["\(Int(boundsWidth))"] = arr
        return CGSize(width: boundsWidth, height: point.y + itemHeight)
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
    func toPlay(_ site: XS_SiteM, model: XS_VideoModel, list: [String], item: String, selected: @escaping (String) -> Void) {
        let player = XS_SitePlayer(site: site, model: model, list: list, item: item, selected: selected)
        vc.present(player, animated: true)
    }
}
