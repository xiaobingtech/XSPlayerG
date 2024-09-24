//
//  XS_Error.swift
//  XSPlayerG
//
//  Created by 韩云智 on 2024/1/15.
//

import Foundation

struct XS_Error {
    static let invalidURL = NSError(domain: "无效 URL", code: 70001)
    static let invalidType = NSError(domain: "无效类型", code: 70002)
    static let invalidData = NSError(domain: "无效数据", code: 70003)
}
