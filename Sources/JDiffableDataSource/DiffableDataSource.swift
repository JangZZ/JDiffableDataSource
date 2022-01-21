//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import UIKit
import Combine

open class JTableViewDiffableDataSource<Section: JSectiontable> {

    // MARK: - Typealias
    public typealias CellProvider = (UITableView, IndexPath, Section.Item) -> UITableViewCell
    public typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Section.Item.ID>

    // MARK: - Private Properties
    private var _dataSource: UITableViewDiffableDataSource<Section, Section.Item.ID>!
    private var _store = JStore<Section>()
    private var _cancellables = Set<AnyCancellable>()

    var snapshotPublisher: SnapshotPublisher {
        return .init(store: _store)
    }

    // MARK: - Initializer
    init(
        tableView: UITableView,
        cellProvider: @escaping (UITableView, IndexPath, Section.Item) -> UITableViewCell
    ) {
        self._dataSource = UITableViewDiffableDataSource<Section, Section.Item.ID>(
            tableView: tableView) { [weak self] tbv, idx, id in
            guard let self = self else { return .init() }
            return cellProvider(tbv, idx, self._store[id])
        }
    }
}

// MARK: - SnapshotPublisher
extension JTableViewDiffableDataSource {

    public struct SnapshotPublisher: Combine.Publisher {

        public typealias Output = Snapshot
        public typealias Failure = Never
        private let store: JStore<Section>

        init(store: JStore<Section>) {
            self.store = store
        }

        public func receive<SB>(
            subscriber: SB
        ) where SB: Subscriber,
                Self.Failure == SB.Failure,
                Self.Output == SB.Input
        {
            let subscription = Subscription(store: store, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }

    private class Subscription<SB: Subscriber>: Combine.Subscription
    where SB.Input == Snapshot, SB.Failure == Never {

        // MARK: - Properties
        private let store: JStore<Section>
        private var _subscriber: SB?
        private var _currentSnapshot: Snapshot?
        private var _cancellables = Set<AnyCancellable>()

        init(store: JStore<Section>, subscriber: SB) {
            self.store = store
            self._subscriber = subscriber
            self.observeStore()
        }

        public func request(_ demand: Subscribers.Demand) {
            if let snapshot = _currentSnapshot {
                _ = _subscriber?.receive(snapshot)
            }
            else {
                _ = _subscriber?.receive(
                    createSnapshot(with: store.sections)
                )
            }
        }

        public func cancel() {
            _currentSnapshot = nil
            _subscriber = nil
            _cancellables.removeAll()
        }

        private func createSnapshot(with sections: [Section]) -> Snapshot {
            var snapshot = Snapshot()
            snapshot.appendSections(sections)
            sections.forEach { section in
                let allIDs = section.items.map(\.id)
                snapshot.appendItems(allIDs, toSection: section)
            }

            return snapshot
        }

        private func update(_ snapshot: inout Snapshot, with newSections: [Section]) {
            snapshot.appendSections(newSections)

            newSections.forEach { section in
                let allIDs = section.items.map(\.id)
                snapshot.appendItems(allIDs, toSection: section)
            }

            if !store.needReloadIDs.isEmpty {
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems(store.needReloadIDs)
                } else {
                    snapshot.reloadItems(store.needReloadIDs)
                }
            }
        }

        private func observeStore() {
            store.$sections
                .sink { [weak self] newSection in
                    guard let self = self else { return }
                    if var currentSnapshot = self._currentSnapshot {
                        self.update(&currentSnapshot, with: newSection)
                        self._currentSnapshot = currentSnapshot
                    }
                    else {
                        self._currentSnapshot = self.createSnapshot(with: newSection)
                    }

                    let _ = self._subscriber?.receive(self._currentSnapshot!)
                }
                .store(in: &_cancellables)
        }
    }
}

// MARK: - Sectionable {
public protocol JSectiontable: Hashable {
    associatedtype Item: Identifiable & Hashable

    var items: [Item] { get }
    var titleHeader: String { get }
}

// MARK: - Observer State
public extension JTableViewDiffableDataSource {

    private func setupDataSource() {
        snapshotPublisher
            .prefix(1)
            .sink { [weak self] snapshot in
                guard let self = self else { return }

                if #available(iOS 15.0, *) {
                    self._dataSource.applySnapshotUsingReloadData(snapshot)
                } else {
                    self._dataSource.apply(snapshot, animatingDifferences: false)
                }
            }
            .store(in: &_cancellables)

        snapshotPublisher
            .dropFirst()
            .sink { [weak self] snapshot in
                guard let self = self else { return }

                self._dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &_cancellables)
    }
}
