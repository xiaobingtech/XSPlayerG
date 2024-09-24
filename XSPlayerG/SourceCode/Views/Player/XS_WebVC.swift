//
//  XS_WebVC.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/13.
//

import SwiftUI
import WebKit

class XS_WebVC: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .flipHorizontal
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var htmlString: String {
"""
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8">
    <style>
        .center {
            text-align: center;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 300px;
        }
    </style>
</head>
<body>
    <span class="center" style="font-size:80px">无效连接!</span>
</body>
</html>
"""
    }
    
    func load(urlStr: String?) {
        wk?.removeFromSuperview()
        wk = .init()
        view.addSubview(wk)
        upWkFrame()
        guard let urlStr = urlStr, let url = URL(string: urlStr) else {
            wk.loadHTMLString(htmlString, baseURL: nil)
            return
        }
        debugPrint(urlStr)
        wk.load(URLRequest(url: url))
    }
    func getTool() -> UIViewController {
        UIViewController()
    }
    
    private var wk: WKWebView!
    private lazy var tool: UIViewController = getTool()
    
    override func viewDidLayoutSubviews() {
        upWkFrame()
        upFrame()
    }
    override func viewDidLoad() {
        view.addSubview(tool.view)
        upFrame()
    }
    private func upFrame() {
        let top = view.safeAreaInsets.top + 44
        tool.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: top)
    }
    private func upWkFrame() {
        if let wk = wk {
            let top = view.safeAreaInsets.top + 44
            wk.frame = CGRect(x: 0, y: top, width: view.bounds.width, height: view.bounds.height - top)
        }
    }
}

struct XS_PlayerTool<T: Hashable>: View {
    @State var selected: T
    let list: [T]
    let name: (T) -> String
    let action: (T) -> Void
    let dismiss: () -> Void
    private func toAction(_ isNext: Bool) {
        guard let index = list.firstIndex(of: selected), let next = isNext ? list.xs_after(index) : list.xs_before(index) else { return }
        selected = list[next]
    }
    var body: some View {
        HStack {
            Button(action: dismiss) {
                Text("取消").padding()
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    toAction(false)
                } label: {
                    Image(systemName: "backward.frame").padding()
                }
                Picker("", selection: $selected) {
                    ForEach(list, id: \.self) { item in
                        Text(name(item)).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxHeight: 40)
                .minimumScaleFactor(0.5)
                Button {
                    toAction(true)
                } label: {
                    Image(systemName: "forward.frame").padding()
                }
            }
        }
        .onChange(of: selected) { oldValue, newValue in
            action(newValue)
        }
    }
}

extension Array {
    func xs_after(_ i: Int) -> Int? {
        i < count - 1 ? i + 1 : nil
    }
    func xs_before(_ i: Int) -> Int? {
        i > 0 ? i - 1 : nil
    }
}
