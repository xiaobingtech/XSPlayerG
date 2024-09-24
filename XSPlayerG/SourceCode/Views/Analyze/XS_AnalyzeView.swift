//
//  XS_AnalyzeView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/15.
//

import SwiftUI
import ComposableArchitecture
import WebKit
import SwiftData

struct XS_AnalyzeView: View {
    var body: some View {
        _Content()
    }
}

private struct _Content: View {
    @Bindable private var store = XS_AnalyzeReducer.store
    @SceneStorage("Analyze.Picker") private var api: String = ""
    @SceneStorage("Analyze.URL") private var url: String = "https://www.baidu.com/"
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDAnalyzeCollect.sort) private var collect: [XS_SDAnalyzeCollect]
    private func onStar() {
        var arr = collect
        if let item = collect.first(where: { $0.url == url }) {
            arr.removeAll { $0 == item }
            modelContext.delete(item)
        } else {
            let new = XS_SDAnalyzeCollect(name: store.title, url: url, sort: 0)
            arr.insert(new, at: 0)
            modelContext.insert(new)
        }
        for (index, item) in arr.enumerated() {
            item.sort = index
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            _WebRepresentable(isAnalyze: store.isAnalyze, api: api, url: .init(get: { url }, set: {
                url = $0
                store.text = $0
            }), title: $store.title, action: $store.action)
            VStack(spacing: 15) {
                HStack {
                    Button(action: onStar) {
                        let isCollect = collect.contains { $0.url == store.text }
                        Image(systemName: isCollect ? "star.fill" : "star")
                    }
                    TextField("", text: $store.text)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .onSubmit {
                            url = store.text
                        }
                }
                HStack {
                    Button {
                        store.action = .goBack
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    Button {
                        store.action = .goForward
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .padding(.horizontal)
                    Spacer()
                    Button {
                        store.listShow = true
                    } label: {
                        Image(systemName: "book")
                    }
                    Spacer()
                    _Piceker(api: $api)
                    Toggle("", isOn: $store.isAnalyze)
                        .fixedSize()
                }
            }
            .padding()
        }
        .navigationTitle(store.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $store.listShow) {
            _Book { url = $0 }
        }
    }
}

private struct _Piceker: View {
    @Binding var api: String
    @Query(filter: #Predicate<XS_SDAnalyze> { $0.isActive }, sort: \XS_SDAnalyze.sort) private var analyze: [XS_SDAnalyze]
    var body: some View {
        Picker("", selection: $api) {
            ForEach(analyze, id: \.url) { item in
                Text(item.name).tag(item.url)
            }
        }
        .pickerStyle(.menu)
        .onAppear {
            if api.isEmpty, let first = analyze.first {
                api = first.url
            }
        }
    }
}

private struct _Book: View {
    let action: (String) -> Void
    @Bindable private var store = XS_AnalyzeReducer.store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDAnalyzeCollect.sort) private var collect: [XS_SDAnalyzeCollect]
    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("取消").padding()
                }
                Spacer()
            }
            List {
                ForEach(collect, id: \.url) { item in
                    Button {
                        store.title = item.name
                        action(item.url)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .foregroundStyle(Color(uiColor: .label))
                            Text(item.url)
                                .font(.footnote)
                                .foregroundStyle(.gray.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
                .xs_edit {
                    collect.count
                } delete: { index in
                    modelContext.delete(collect[index])
                } move: { from, to in
                    collect[from].sort = to
                }
            }
        }
    }
}

private struct _WebRepresentable: UIViewControllerRepresentable {
    let isAnalyze: Bool
    let api: String
    @Binding var url: String
    @Binding var title: String
    @Binding var action: XS_AnalyzeReducer._Action
    func makeUIViewController(context: Context) -> _WebVC {
        let vc = _WebVC()
        vc.wk.navigationDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: _WebVC, context: Context) {
        context.coordinator.load(uiViewController, api: api, url: url, isAnalyze: isAnalyze, action: action)
    }
    func makeUIView(context: Context) -> WKWebView {
        let wk = WKWebView()
        wk.navigationDelegate = context.coordinator
        return wk
    }
    class _WebVC: UIViewController {
        lazy var wk: _Web = .init()
        func loadWk(_ url: String) {
            if wk.superview == nil {
                jx.removeFromSuperview()
                wk.frame = view.bounds
                view.addSubview(wk)
            }
            wk.xs_load(url)
        }
        private lazy var jx: _Web = .init()
        func loadJx(_ url: String) {
            if jx.superview == nil {
                wk.removeFromSuperview()
                jx.frame = view.bounds
                view.addSubview(jx)
            }
            jx.xs_load(url)
        }
        func change(action: XS_AnalyzeReducer._Action) {
            let web = view.subviews.last! as! WKWebView
            switch action {
            case .done: return
            case .goBack: if web.canGoBack { web.goBack() }
            case .goForward: if web.canGoForward { web.goForward() }
            }
        }
        override func viewDidLayoutSubviews() {
            wk.frame = view.bounds
            jx.frame = view.bounds
        }
    }
    class _Web: WKWebView {
        lazy var save: String = ""
        func xs_load(_ url: String) {
            if url == save { return }
            save = url
            if let url = URL(string: url) {
                load(URLRequest(url: url))
            } else {
                loadHTMLString("", baseURL: nil)
            }
        }
    }
    func makeCoordinator() -> _Coordinator {
        _Coordinator(self)
    }
    class _Coordinator: NSObject, WKNavigationDelegate {
        private var parent: _WebRepresentable
        init(_ parent: _WebRepresentable) {
            self.parent = parent
        }
        func load(_ web: _WebVC, api: String, url: String, isAnalyze: Bool, action: XS_AnalyzeReducer._Action) {
            isAnalyze ? web.loadJx(api + url) : web.loadWk(url)
            if action != .done {
                web.change(action: action)
                parent.action = .done
                if !isAnalyze {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.upWeb(web.wk)
                    }
                }
            }
        }
        private func upWeb(_ webView: _Web) {
            parent.title = webView.title ?? "解析"
            if let url = webView.url?.relativeString {
                webView.save = url
                parent.url = url
            }
        }
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if let webView = webView as? _Web {
                upWeb(webView)
            }
            completionHandler(.performDefaultHandling, nil)
            return
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let webView = webView as? _Web {
                upWeb(webView)
            }
        }
//        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//            
//        }
//        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//            decisionHandler(.allow)
//        }
//        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//            decisionHandler(.allow)
//        }
    }
}
