//
//  File.swift
//  
//
//  Created by TruongGiang on 24/01/2022.
//

import Combine

public extension Publisher {

    func assign<S: JSectiontable>(
        to dataSource: JTableViewDiffableDataSource<S.Item>
    ) -> AnyCancellable where Output == [S], Failure == Never {
        return self.sink(receiveValue: { [weak dataSource] sections in
            dataSource?.update(sections)
        })
    }

    func assign<I: JItemable>(
        to dataSource: JTableViewDiffableDataSource<I>
    ) -> AnyCancellable where Output == [I], Failure == Never {
        return self.sink(receiveValue: { [weak dataSource] items in
            dataSource?.update(items)
        })
    }
}
