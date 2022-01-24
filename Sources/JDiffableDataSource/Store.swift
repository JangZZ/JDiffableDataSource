//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import Foundation

public class JStore<I: JItemable> {

    typealias ID = I.ID

    // MARK: - Private Properties
    @Published private(set) var sections: [AnySection<I>] = []
    private(set) var allItems: Set<I> = []
    private(set) var allIDs: [ID] = []
    private(set) var needReloadIDs: [ID] = []

    // MARK: - Properties
    func update(_ newSections: [AnySection<I>]) {
        let oldItems = self.allItems
        let newItems = Set<I>(newSections.flatMap(\.items))

        needReloadIDs = Array(
            newItems.subtracting(oldItems)
                .filter({ allIDs.contains($0.id) })
                .map(\.id)
        )

        allItems = newItems
        allIDs = allItems.map(\.id)
        sections = newSections
    }

    subscript(id: ID) -> I {
        get {
            precondition(
                self.allItems.first { $0.id == id } != nil,
              "Element identity must remain constant"
            )
            return allItems.first(where: { $0.id == id })!

        }

        set(newValue) {
            if allItems.firstIndex(where: { $0.id == id }) != nil {
                allItems.update(with: newValue)
            }
            else {
                allItems.insert(newValue)
            }
        }
    }
}
