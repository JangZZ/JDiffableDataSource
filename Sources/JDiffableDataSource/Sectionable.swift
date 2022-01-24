//
//  File.swift
//  
//
//  Created by TruongGiang on 24/01/2022.
//

import Foundation

// MARK: - Sectionable {
public protocol JSectiontable: Hashable {
    associatedtype Item: JItemable

    /// `Important` The ID for section specific for each section should never change at run time
    var ID: String { get }

    /// The Items for each section
    var items: [Item] { get }

    var titleHeader: String { get }
}

public extension JSectiontable {

    /// Default implement for title header because some time
    /// Section will not have the header tile
    var titleHeader: String { return .JConstant.empty }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ID == rhs.ID
    }
}
