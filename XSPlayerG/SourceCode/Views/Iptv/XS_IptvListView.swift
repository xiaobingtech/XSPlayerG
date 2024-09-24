//
//  XS_IptvListView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import SwiftUI

struct XS_IptvListView: View {
    let group: XS_IptvGroupModel
    @State private var selection: XS_IptvItemModel?
    var body: some View {
        _ToPlayer { obs in
            List(group.list, id: \.self) { item in
                Button {
                    obs.toPlay(item, list: group.list) { item in
                        selection = item
                    }
                } label: {
                    Text(item.name)
                }
                .foregroundStyle(item == selection ? .red : Color(uiColor: .label))
            }
        }
        .navigationTitle(group.title)
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
    func toPlay(_ item: XS_IptvItemModel, list: [XS_IptvItemModel], selected: @escaping (XS_IptvItemModel) -> Void) {
        let player = XS_IptvPlayer(item: item, list: list, selected: selected)
        vc.present(player, animated: true)
    }
}
