//
//  XS_SiteView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/26.
//

import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI
import SwiftData

struct XS_SiteView: View {
    let site: XS_SiteM
    var body: some View {
        _Content(site: site)
            .navigationTitle(site.name)
    }
}

private struct _Content: View {
    private let site: XS_SiteM
    @Bindable private var searchStore: StoreOf<XS_SiteSearchReducer>
    @State private var isPresented: Bool = false
    private let store: StoreOf<XS_SiteReducer> = XS_SiteReducer.store
    init(site: XS_SiteM) {
        self.site = site
        searchStore = XS_SiteSearchReducer.store(site: site)
    }
    var body: some View {
        Group {
            if isPresented {
                XS_SiteSearchView(store: searchStore)
            } else {
                _List(store: store, site: site)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .searchable(text: $searchStore.text, isPresented: $isPresented, prompt: "搜索关键字")
        .onSubmit(of: .search) {
            searchStore.send(.search)
        }
        .onChange(of: isPresented) { oldValue, newValue in
            guard newValue != oldValue, !newValue else { return }
            searchStore.text = ""
            searchStore.current = ""
            searchStore.list = []
            searchStore.isLoading = false
        }
        .onAppear {
            store.send(.onAppear(site))
        }
    }
}

private struct _Class: View {
    @Bindable var store: StoreOf<XS_SiteReducer>
    @Binding var isList: Bool
    var body: some View {
        if let film = store.film {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        _Picker(selection: $store.currentClass.sending(\.setClass), name: "分类", items: film.xs_classData, getName: \.type_name)
                        if let items = film.filters[store.currentClass.type_id] {
                            _Filters(store: store, items: items)
                        }
                    }
                    .padding(.horizontal)
                }
                Divider().frame(height: 20)
                Button {
                    isList.toggle()
                } label: {
                    Image(systemName: isList ? "square.fill.text.grid.1x2" : "square.grid.2x2.fill")
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.trailing)
        }
    }
}
private struct _Filters: View {
    let store: StoreOf<XS_SiteReducer>
    let items: [XS_FilmModel._FilterData]
    private func selection(_ key: String) -> Binding<XS_FilmModel._FilterData._Value> {
        .init {
            store.filters[key] ?? .init(n: "全部")
        } set: { value in
            store.send(.setFilters(key, value))
        }
    }
    var body: some View {
        ForEach(items) { item in
            _Picker(selection: selection(item.key), name: item.name, items: item.value, getName: \.n)
        }
    }
}
private struct _Picker<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let name: String
    let items: [T]
    let getName: (T) -> String
    var body: some View {
        HStack(spacing: 0) {
            Text(name + ":")
            Picker("", selection: $selection) {
                ForEach(items) { item in
                    Text(getName(item))
                        .tag(item)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

private struct _List: View {
    let store: StoreOf<XS_SiteReducer>
    let site: XS_SiteM
    @SceneStorage("XS_SiteView.isList") private var isList: Bool = true
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                _Class(store: store, isList: $isList)
                if isList {
                    _TList(store: store, site: site)
                } else {
                    _CList(store: store, site: site)
                }
                LazyVStack {
                    XS_LoadingView(item: store.loading)
                        .padding(.top)
                        .onAppear {
                            store.send(.loadMore)
                        }
                }
//                GeometryReader { proxy in
//                    let h = UIScreen.main.bounds.height*1.5
//                    WithViewStore(store, observe: \.loading) { vs in
//                        XS_LoadingView(item: vs.state)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .onChange(of: proxy.frame(in: .global).minY) { oldValue, newValue in
//                                guard vs.status == .idle, newValue < h else { return }
//                                vs.send(.loadMore)
//                            }
//                    }
//                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
private struct _TList: View {
    let store: StoreOf<XS_SiteReducer>
    let site: XS_SiteM
    var body: some View {
        VStack {
            ForEach(store.list) { item in
                NavigationLink(item: .detail(site: site, id: item.vod_id, model: item)) {
                    _TItem(item: item)
                }
            }
        }
        .padding(20)
    }
}
private struct _TItem: View {
    let item: XS_VideoModel
    var body: some View {
        HStack(alignment: .top) {
            WebImage(url: URL(string: item.vod_pic))
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            VStack {
                Text(item.vod_name)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack {
                    Text(item.xs_remark)
                    Spacer()
                    Text(item.xs_time)
                }
                .font(.footnote)
            }
            .foregroundColor(Color(uiColor: .label))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background()
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct _CList: View {
    let store: StoreOf<XS_SiteReducer>
    let site: XS_SiteM
    var body: some View {
        _ListLayout {
            ForEach(store.list) { item in
                NavigationLink(item: .detail(site: site, id: item.vod_id, model: item)) {
                    _CItem(item: item)
                }
            }
        }
    }
}
private struct _CItem: View {
    let item: XS_VideoModel
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottom) {
                    WebImage(url: URL(string: item.vod_pic))
                        .resizable()
                        .scaledToFit()
                    Text(item.xs_time)
                        .foregroundColor(.white)
                        .padding(5)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.3))
                }
                Text(item.xs_remark)
                    .foregroundColor(.black)
                    .padding(5)
                    .background(Color("Gold"))
                    .clipShape(.rect(cornerRadii: .init(bottomLeading: 10)))
            }
            .font(.footnote)
            .minimumScaleFactor(0.5)
            Text(item.vod_name)
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .label))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(5)
        }
        .frame(width: 160)
        .background()
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct _ListLayout: Layout {
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
            var point = arr[index]
            point.x += bounds.minX
            point.y += bounds.minY
            subviews[index].place(
                at: point,
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }
    private func size(boundsWidth: Double, subviews: Subviews) -> CGSize {
        var columns: [_Column] = []
        let width: Double =  160
        let spacing: Double = 20
        var x: Double = 0
        while x + width + spacing*2 < boundsWidth {
            columns.append(.init(x: x, y: spacing))
            x += (width + spacing)
        }
        x = (boundsWidth + spacing - x)/2
        var arr: [CGPoint] = []
        var maxY: Double = 0
        for index in subviews.indices {
            guard let item = columns.xs_min() else { continue }
            arr.append(CGPoint(x: x + item.x, y: item.y))
            let size = subviews[index].sizeThatFits(.unspecified)
            item.y += (size.height + spacing)
            maxY = max(maxY, item.y)
        }
        dict["\(Int(boundsWidth))"] = arr
        return CGSize(width: boundsWidth, height: maxY)
    }
}

private class _Column {
    let x: Double
    var y: Double
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
private extension [_Column] {
    func xs_min() -> _Column? {
        var min: _Column?
        for item in self {
            if let v = min, item.y >= v.y {
                continue
            }
            min = item
        }
        return min
    }
    func xs_max() -> Double {
        reduce(0) { Swift.max($0, $1.y) }
    }
}

//struct MyEqualWidthHStack: Layout {
//    func sizeThatFits(
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout Void
//    ) -> CGSize {
//        // Return a size.
//        guard !subviews.isEmpty else { return .zero }
//        
//        let maxSize = maxSize(subviews: subviews)
//        let spacing = spacing(subviews: subviews)
//        let totalSpacing = spacing.reduce(0) { $0 + $1 }
//        
//        return CGSize(
//            width: maxSize.width * CGFloat(subviews.count) + totalSpacing,
//            height: maxSize.height)
//    }
//    
//    func placeSubviews(
//        in bounds: CGRect,
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout Void
//    ) {
//        // Place child views.
//        guard !subviews.isEmpty else { return }
//        
//        let maxSize = maxSize(subviews: subviews)
//        let spacing = spacing(subviews: subviews)
//        
//        let placementProposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)
//        var x = bounds.minX + maxSize.width / 2
//        
//        for index in subviews.indices {
//            subviews[index].place(
//                at: CGPoint(x: x, y: bounds.midY),
//                anchor: .center,
//                proposal: placementProposal)
//            x += maxSize.width + spacing[index]
//        }
//    }
//    
//    private func maxSize(subviews: Subviews) -> CGSize {
//        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
//        let maxSize: CGSize = subviewSizes.reduce(.zero) { currentMax, subviewSize in
//            CGSize(
//                width: max(currentMax.width, subviewSize.width),
//                height: max(currentMax.height, subviewSize.height))
//        }
//        
//        return maxSize
//    }
//    
//    private func spacing(subviews: Subviews) -> [CGFloat] {
//        subviews.indices.map { index in
//            guard index < subviews.count - 1 else { return 0 }
//            return subviews[index].spacing.distance(
//                to: subviews[index + 1].spacing,
//                along: .horizontal)
//        }
//    }
//}

/*
private struct Rank: LayoutValueKey {
    static let defaultValue: Int = 1
}

extension View {
    func rank(_ value: Int) -> some View {
        layoutValue(key: Rank.self, value: value)
    }
}

func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
) {
    let radius = min(bounds.size.width, bounds.size.height) / 3.0
    let angle = Angle.degrees(360.0 / Double(subviews.count)).radians

    let ranks = subviews.map { subview in
        subview[Rank.self]
    }
    let offset = getOffset(ranks)

    for (index, subview) in subviews.enumerated() {
        var point = CGPoint(x: 0, y: -radius)
            .applying(CGAffineTransform(
                rotationAngle: angle * Double(index) + offset))
        point.x += bounds.midX
        point.y += bounds.midY
        subview.place(at: point, anchor: .center, proposal: .unspecified)
    }
}

struct Profile: View {
    var pets: [Pet]
    var isThreeWayTie: Bool

    var body: some View {
        let layout = isThreeWayTie ? AnyLayout(HStackLayout()) : AnyLayout(MyRadialLayout())

        Podium() // Creates the background that shows ranks.
            .overlay(alignment: .top) {
                layout {
                    ForEach(pets) { pet in
                        Avatar(pet: pet)
                            .rank(rank(pet))
                    }
                }
                .animation(.default, value: pets)
            }
    }
}
*/
