//
//  Item.swift
//  BPA_合隙
//
//  Created by JJ Zhang on 2026/11/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
