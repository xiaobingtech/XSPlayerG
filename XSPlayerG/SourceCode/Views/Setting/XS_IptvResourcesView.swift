//
//  XS_IptvResourcesView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/19.
//

import SwiftUI
import SwiftData

struct XS_IptvResourcesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDIptv.sort) private var data: [XS_SDIptv]
    @State private var loadings: [String] = []
    var body: some View {
        List {
            ForEach(data, id: \.url) { item in
                NavigationLink(item: .setIptvEdit(item)) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        if let test = item.test {
                            Text(test ? "有效" : "失效")
                                .font(.footnote)
                                .foregroundStyle(test ? .green : .red)
                        }
                        Toggle("", isOn: .init(get: { item.isActive }, set: { item.isActive = $0 }))
                            .fixedSize()
                    }
                }
            }
            .xs_edit {
                data.count
            } delete: { index in
                modelContext.delete(data[index])
            } move: { from, to in
                data[from].sort = to
            }
        }
        .navigationTitle("电视资源")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if loadings.isEmpty {
                    Button("检测", action: onTest)
                } else {
                    ProgressView()
                }
                NavigationLink(item: .setIptvEdit(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func onTest() {
        if data.isEmpty {
            loadings.removeAll()
            return
        }
        let data = data
        loadings = .init(repeating: "", count: data.count)
        for item in data {
            Task  {
                let test: Bool
                do {
                    test = try await !XS_NetWork.shared.iptvList(item.url).isEmpty
                } catch {
                    debugPrint(error.localizedDescription)
                    test = false
                }
                DispatchQueue.main.async {
                    item.test = test
                    item.isActive = test
                    loadings.removeLast()
                }
            }
        }
    }
}
