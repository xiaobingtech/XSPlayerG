//
//  XS_ListEditModifier.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/2/19.
//

import SwiftUI

extension DynamicViewContent {
    func xs_edit(count: @escaping () -> Int, delete: @escaping (Int) -> Void, move: @escaping (Int, Int) -> Void) -> some DynamicViewContent {
        xs_move(move).xs_delete(count: count, delete: delete, move: move)
    }
    
    func xs_delete(count: @escaping () -> Int, delete: @escaping (Int) -> Void, move: @escaping (Int, Int) -> Void) -> some DynamicViewContent {
        onDelete { indexSet in
            xs_onDelete(indexSet, count, delete, move)
        }
    }
    private func xs_onDelete(_ indexSet: IndexSet, _ count: () -> Int, _ delete: (Int) -> Void, _ move: (Int, Int) -> Void) {
        var all = Array(0..<count())
        all.remove(atOffsets: indexSet)
        indexSet.forEach { index in
            delete(index)
        }
        for (index, item) in all.enumerated() {
            move(item, index)
        }
    }
    
    func xs_move(_ move: @escaping (Int, Int) -> Void) -> some DynamicViewContent {
        onMove { indexSet, offset in
            xs_onMove(indexSet, offset, move)
        }
    }
    private func xs_onMove(_ indexSet: IndexSet, _ offset: Int, _ move: (Int, Int) -> Void) {
        indexSet.forEach { index in
            if index < offset {
                move(index, offset - 1)
                for index in (index+1)..<offset {
                    move(index, index - 1)
                }
            } else if index > offset {
                move(index, offset)
                for index in offset..<index {
                    move(index, index+1)
                }
            }
            debugPrint("\(index) - \(offset)")
        }
    }
}
