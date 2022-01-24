//
//  File.swift
//  
//
//  Created by TruongGiang on 24/01/2022.
//

import Foundation

// MARK: - AnySection

/// This struct provide type erasure for a concrete section type conform JSectiontable
public struct AnySection<I: JItemable>: JSectiontable {
    public var items: [I] {
        return _items
    }

    let _items: [I]
    let _id: String

    public var ID: String {
        _id
    }

    public init<S: JSectiontable>(_ section: S) where I == S.Item {
        self._items = section.items
        self._id = section.ID
    }
}

// MARK: - Default Section
enum DefaultSection<I: JItemable>: JSectiontable {
    case main(items: [I])

    var ID: String {
        return .JConstant.defaultSectionID
    }

    var items: [I] {
        if case let .main(items) = self {
            return items
        }
        return []
    }
}
