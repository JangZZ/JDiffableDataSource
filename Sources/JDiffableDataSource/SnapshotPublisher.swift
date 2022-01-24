//
//  File.swift
//  
//
//  Created by TruongGiang on 24/01/2022.
//

import Foundation
import Combine

// MARK: - SnapshotPublisher
extension JTableViewDiffableDataSource {

    public struct SnapshotPublisher: Combine.Publisher {

        public typealias Output = Snapshot
        public typealias Failure = Never
        private let store: JStore<I>

        init(store: JStore<I>) {
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
        private let store: JStore<I>
        private var _subscriber: SB?
        private var _cancellables = Set<AnyCancellable>()

        init(store: JStore<I>, subscriber: SB) {
            self.store = store
            self._subscriber = subscriber
            self.observeStore()
        }

        public func request(_ demand: Subscribers.Demand) {}

        public func cancel() {
            _subscriber = nil
            _cancellables.removeAll()
        }

        private func createSnapshot(with sections: [AnySection<I>]) -> Snapshot {
            var snapshot = Snapshot()
            sections.forEach { section in
                let allIDs = section.items.map(\.id)
                snapshot.appendSections([section])
                snapshot.appendItems(allIDs, toSection: section)
            }

            return snapshot
        }

        private func reloadItemIfNeeded(_ snapshot: inout Snapshot, with newSections: [AnySection<I>]) {
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
                    var newSnapshot = self.createSnapshot(with: newSection)
                    self.reloadItemIfNeeded(&newSnapshot, with: newSection)

                    let _ = self._subscriber?.receive(newSnapshot)
                }
                .store(in: &_cancellables)
        }
    }
}
