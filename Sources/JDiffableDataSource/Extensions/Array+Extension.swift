//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import Foundation

extension Array {
    mutating func _modifyForEach(_ body: (_ index: Index, _ element: inout Element) -> ()) {
        for index in indices {
            _modifyElement(atIndex: index) { body(index, &$0) }
        }
    }

    mutating func _modifyElement(atIndex index: Index, _ modifyElement: (_ element: inout Element) -> ()) {
        if var element = self[_safe: index] {
            modifyElement(&element)
            self[index] = element
        }
    }
}

extension Array where Element: JSectiontable {
    var toTitleHeader: TitleHeaderSection {
        return { index -> String? in
            if let section = self[_safe: index] {
                return section.titleHeader
            }
            return nil
        }
    }
}
