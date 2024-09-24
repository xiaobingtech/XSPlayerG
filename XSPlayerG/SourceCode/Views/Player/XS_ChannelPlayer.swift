//
//  XS_ChannelPlayer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/19.
//

import SwiftUI
import SwiftData

class XS_ChannelPlayer: XS_WebVC {
    private var item: XS_SDChannel
    private let list: [XS_SDChannel]
    private let selected: (XS_SDChannel) -> Void
    init(item: XS_SDChannel, list: [XS_SDChannel], selected: @escaping (XS_SDChannel) -> Void) {
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
    private func load(item: XS_SDChannel) {
        self.item = item
        self.selected(item)
        load(urlStr: item.url)
    }
}
