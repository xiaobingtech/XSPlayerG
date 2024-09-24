//
//  XS_RootView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/12.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

var xs_r18KeyWords: [String] = []
let xs_r18: [String] = ["伦理", "论理", "倫理", "福利", "激情", "理论", "写真", "情色", "美女", "街拍", "赤足", "性感", "里番", "视频秀", "18禁", "麻豆", "91"]
extension String {
    var is18: Bool { !xs_r18KeyWords.contains { self.contains($0) } }
}

struct XS_RootView: View {
//    private let store = XS_RootReducer.store
    @AppStorage("XS_RootView.Guide") private var isGuide: Bool = true
    var body: some View {
        if isGuide {
            NavigationStack {
                XS_GuideView(isGuide: $isGuide)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isGuide = false
                            } label: {
                                Text("跳过").padding()
                            }
                        }
                    }
            }
        } else {
            _Content()
        }
    }
    
}

private struct _Content: View {
    @Query private var search: [XS_SDSiteSearch]
    var body: some View {
        if let item = search.first {
            xs_r18KeyWords = item.is18 ? xs_r18 : []
        }
        return _Split()
    }
}

private struct _Split: View {
    var body: some View {
        XS_SplitView { type in
            XS_NavView {
                _NavContent(type: type)
            }
        }
    }
}

private struct _NavContent: View {
    let type: XS_SplitReducer.State.XS_SplitType
    var body: some View {
        Group {
            switch type {
            case .影视: XS_FilmView()
            case .电视: XS_IptvView()
            case .解析: XS_AnalyzeView()
            case .设置: XS_SettingView()
            }
        }
        .background()
    }
}

//.environment(\.xs_18, search.first?.is18 ?? true)
//@Environment(\.xs_data) private var data
//private struct XS_18Key: EnvironmentKey {
//    static let defaultValue: Bool = true
//}
//extension EnvironmentValues {
//    var xs_18: Bool {
//        get { self[XS_18Key.self] }
//        set { self[XS_18Key.self] = newValue }
//    }
//}
