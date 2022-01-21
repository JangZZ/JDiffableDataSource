//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import Foundation

public class JStore<S: JSectiontable> {

    typealias ID = S.Item.ID

    // MARK: - Private Properties
    @Published private(set) var sections: [S] = []
    private(set) var allItems: Set<S.Item> = []
    private(set) var allIDs: [ID] = []
    private(set) var needReloadIDs: [ID] = []

    // MARK: - Properties
    func update(_ newSections: [S]) {
        let oldItems = self.allItems
        let newItems = Set<S.Item>(newSections.flatMap(\.items))

        needReloadIDs = Array(
            newItems.subtracting(oldItems)
                .filter({ allIDs.contains($0.id) })
                .map(\.id)
        )

        allItems = newItems
        allIDs = allItems.map(\.id)
        sections = newSections
    }

    subscript(id: ID) -> S.Item {
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
