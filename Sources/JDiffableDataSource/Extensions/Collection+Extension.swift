//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import Foundation

extension Collection {
    subscript (_safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }

    var lastIndex: Int {
        return count - 1
    }
}
