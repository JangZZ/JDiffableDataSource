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

    private let _items: [I]
    private let _id: String
    private let _titleHeader: String

    public var items: [I] {
        return _items
    }

    public var ID: String {
        return _id
    }

    public var titleHeader: String {
        return _titleHeader
    }

    public init<S: JSectiontable>(_ section: S) where I == S.Item {
        self._items = section.items
        self._id = section.ID
        self._titleHeader = section.titleHeader
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ID == rhs.ID
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ID == rhs.ID
    }
}
