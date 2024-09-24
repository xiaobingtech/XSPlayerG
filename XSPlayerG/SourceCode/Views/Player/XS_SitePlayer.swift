//
//  XS_SitePlayer.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import SwiftUI

class XS_SitePlayer: XS_WebVC {
    private let site: XS_SiteM
    private let model: XS_VideoModel
    private let list: [String]
    private let selected: (String) -> Void
    private var item: String
    init(site: XS_SiteM, model: XS_VideoModel, list: [String], item: String, selected: @escaping (String) -> Void) {
        self.site = site
        self.model = model
        self.list = list
        self.selected = selected
        self.item = item
        super.init()
        loadUrl(item)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getTool() -> UIViewController {
        let view = XS_PlayerTool(selected: item, list: list) { item in
            String(item.split(separator: "$").first ?? "--")
        } action: { [weak self] item in
            guard let self else { return }
            self.loadUrl(item)
        } dismiss: { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true)
        }
        return UIHostingController(rootView: view)
    }
    private func loadUrl(_ item: String) {
        self.item = item
        self.selected(item)
        Task {
            guard let urlStr = await getURl(item) else {
                load(urlStr: nil)
                return
            }
            load(urlStr: urlStr)
        }
    }
    private func getURl(_ item: String) async -> String? {
        let items = item.split(separator: "$")
        guard items.count == 2 else { return nil }
        var real = String(items[1])
        if site.type == .drpy_js0 {
            do {
                real = try await XS_NetWork.shared.getRealUrl(site: site, url: real)
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        if real.contains("mp4") || real.contains("mkv") { // mp4
            return real
        } else if real.contains("flv") { // flv
            return real
        }
        if !site.playUrl.isEmpty {
            do {
                let data = try await XS_NetWork.shared.getConfig(url: site.playUrl + real)
                let dict = try JSONSerialization.jsonObject(with: data) as! NSDictionary
                return dict["url"] as? String
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        guard !real.isEmpty, real.contains("://") else { return nil }
        return real
    }
}
