//
//  XS_SplitView.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/26.
//

import SwiftUI
import ComposableArchitecture

struct XS_SplitView<Content: View>: View {
    typealias Item = XS_SplitReducer.State.XS_SplitType
    @ViewBuilder let content: (Item) -> Content
    
    private let store = XS_SplitReducer.store
    private let width: Double = 150
    var body: some View {
        ZStack(alignment: .leading) {
            List(Item.all) { item in
                Button(item == store.type ? "> \(item.rawValue) <" : item.rawValue) {
                    store.send(.setType(item))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            }
            .frame(width: width)
            _Content(width: width) {
                content(store.type)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct _Content<Content: View>: View {
    let width: Double
    @ViewBuilder let content: () -> Content
    
    private let store = XS_SplitReducer.store
    var body: some View {
        ZStack {
            content()
            Color.black.opacity(store.show ? 0.2 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    store.send(.setShow(false))
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: store.show ? width : 0)
        .animation(.default, value: store.show)
    }
}
