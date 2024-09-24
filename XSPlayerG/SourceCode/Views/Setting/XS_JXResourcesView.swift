//
//  XS_JXResourcesView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/18.
//

import SwiftUI
import SwiftData

struct XS_JXResourcesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \XS_SDAnalyze.sort) private var analyze: [XS_SDAnalyze]
    @State private var loadings: [String] = []
    var body: some View {
        List {
            ForEach(analyze, id: \.url) { item in
                NavigationLink(item: .setJxEdit(item)) {
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
//            .onMove(perform: onMove)
//            .onDelete(perform: onDelete)
            .xs_edit {
                analyze.count
            } delete: { index in
                modelContext.delete(analyze[index])
            } move: { from, to in
                analyze[from].sort = to
            }

        }
        .navigationTitle("解析资源")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if loadings.isEmpty {
                    Button("检测", action: onTest)
                } else {
                    ProgressView()
                }
                NavigationLink(item: .setJxEdit(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
//    private func onDelete(_ indexSet: IndexSet) {
//        var arr = analyze
//        indexSet.forEach { index in
//            print(analyze.count)
//            modelContext.delete(arr[index])
//            print(analyze.count)
//            arr.remove(at: index)
//        }
//        for (index, item) in arr.enumerated() {
//            item.sort = index
//        }
//    }
//    private func onMove(_ indexSet: IndexSet, _ offset: Int) {
//        indexSet.forEach { index in
//            if index < offset {
//                analyze[index].sort = offset - 1
//                for index in (index+1)..<offset {
//                    analyze[index].sort -= 1
//                }
//            } else if index > offset {
//                analyze[index].sort = offset
//                for index in offset..<index {
//                    analyze[index].sort += 1
//                }
//            }
//            debugPrint("\(index) - \(offset)")
//        }
//    }
    private func onTest() {
        if analyze.isEmpty {
            loadings.removeAll()
            return
        }
        let analyze = analyze
        loadings = .init(repeating: "", count: analyze.count)
        for item in analyze {
            Task  {
                let test = await XS_NetWork.shared.check(url: item.url)
                DispatchQueue.main.async {
                    item.test = test
                    item.isActive = test
                    loadings.removeLast()
                }
            }
        }
    }
}
