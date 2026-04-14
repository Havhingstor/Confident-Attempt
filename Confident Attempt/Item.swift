//
//  Item.swift
//  Confident Attempt
//
//  Created by Paul on 14.04.26.
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
