//
//  XS_NetWeb.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/14.
//

import WebKit
import Alamofire

class XS_NetWeb: NSObject {
    static func request(_ url: URLConvertible) async throws -> String {
        let net = XS_NetWeb()
        let url = try url.asURL()
        let actorStream = AsyncStream<_Actor> { continuation in
            net.continuation = continuation
            net.request(url)
        }
        var result: String?
        for await actor in actorStream {
            result = await actor.content
        }
        if let result = result {
            return result
        }
        throw XS_Error.invalidURL
    }
    
    private actor _Actor {
        var content: String
        init(content: String) {
            self.content = content
        }
    }
    private var continuation: AsyncStream<_Actor>.Continuation!
    private var wk: WKWebView!
    private var url: URL!
    
    func request(_ url: URL) {
        self.url = url
        DispatchQueue.main.async {
            self.wk = .init()
            self.wk.navigationDelegate = self
            self.wk.load(URLRequest(url: url))
        }
    }
}

extension XS_NetWeb: WKNavigationDelegate {
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        if let url = webView.url, url != self.url {
//            continuation.yield(_Actor(url: url))
//        }
////        completionHandler(.cancelAuthenticationChallenge, nil)
//        completionHandler(.useCredential, nil)
//        return
//    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        "document.documentElement.innerHTML"
        webView.evaluateJavaScript("document.body.innerText") { [weak self] res, error in
            guard let self else { return }
            if error == nil, let res = res as? String {
                self.continuation.yield(_Actor(content: res))
            }
            self.continuation.finish()
        }
        webView.navigationDelegate = nil
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation.finish()
        webView.navigationDelegate = nil
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation.finish()
        webView.navigationDelegate = nil
    }
//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//        let res = navigationResponse.response as! HTTPURLResponse
//        let header = res.allHeaderFields
//        decisionHandler(.cancel)
//    }
}
