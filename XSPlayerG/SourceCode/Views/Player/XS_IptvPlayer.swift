//
//  XS_IptvPlayer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import SwiftUI
import SwiftData

class XS_IptvPlayer: XS_WebVC {
    private var item: XS_IptvItemModel
    private let list: [XS_IptvItemModel]
    private let selected: (XS_IptvItemModel) -> Void
    init(item: XS_IptvItemModel, list: [XS_IptvItemModel], selected: @escaping (XS_IptvItemModel) -> Void) {
        self.item = item
        self.list = list
        self.selected = selected
        super.init()
        load(item: item)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getTool() -> UIViewController {
        let view = XS_IptvPlayerTool(selected: item, list: list) { item in
            item.name
        } url: { item in
            item.url
        } action: { [weak self] item in
            guard let self else { return }
            self.load(item: item)
        } dismiss: { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true)
        }
            .modelContainer(sharedModelContainer)
        return UIHostingController(rootView: view)
    }
    private func load(item: XS_IptvItemModel) {
        self.item = item
        self.selected(item)
        load(urlStr: item.url)
    }
}

struct XS_IptvPlayerTool<T: Hashable>: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDChannel.sort) private var data: [XS_SDChannel]
    @State var current: T?
    let selected: T
    let list: [T]
    let name: (T) -> String
    let url: (T) -> String
    let action: (T) -> Void
    let dismiss: () -> Void
    var body: some View {
        HStack {
            XS_PlayerTool(selected: selected, list: list, name: name, action: {
                current = $0
                action($0)
            }, dismiss: dismiss)
            let url = url(current ?? selected)
            let isCollect = data.contains { $0.url == url }
            Button {
                if isCollect {
                    if let index = data.firstIndex(where: { $0.url == url }) {
                        var arr = data
                        let item = arr.remove(at: index)
                        modelContext.delete(item)
                        for (index, item) in arr.enumerated() {
                            item.sort = index
                        }
                    }
                } else {
                    let name = name(current ?? selected)
                    let new = XS_SDChannel(name: name, url: url, sort: data.count)
                    modelContext.insert(new)
                }
            } label: {
                Image(systemName: isCollect ? "heart.fill" : "heart")
            }
            .padding(.trailing)
        }
    }
}
