//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import UIKit
import Combine

public final class JTableViewDiffableDataSource<Section: JSectiontable> {

    // MARK: - Typealias
    public typealias CellProvider = (UITableView, IndexPath, Section.Item) -> UITableViewCell
    public typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Section.Item.ID>

    // MARK: - Private Properties
    private var _dataSource: JDataSource<Section>!
    private var _store = JStore<Section>()
    private var _cancellables = Set<AnyCancellable>()

    var snapshotPublisher: SnapshotPublisher {
        return .init(store: _store)
    }

    // MARK: - Initializer
    public init(
        tableView: UITableView,
        cellProvider: @escaping (UITableView, IndexPath, Section.Item) -> UITableViewCell
    ) {
        self._dataSource = JDataSource<Section>(
            tableView: tableView) { [weak self] tbv, idx, id in
            guard let self = self else { return .init() }
            return cellProvider(tbv, idx, self._store[id])
        }

        self.setupDataSource()
    }
}

extension JTableViewDiffableDataSource {
    public func titleSection(_ toTitleSection: @escaping TitleHeaderSection) -> Self {
        _dataSource.titleHeaderSection = toTitleSection
        return self
    }
}

public class JDataSource<S: JSectiontable>: UITableViewDiffableDataSource<S, S.Item.ID> {

    var titleHeaderSection: TitleHeaderSection? = nil

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleHeaderSection?(section)
    }
}

// MARK: - Computed Properties
extension JTableViewDiffableDataSource {

    ///  Use this computed variables when your tableview have multiple sections
    public var sections: [Section] {
        get { _store.sections }
        set {
            // Update title header for datasource
            _dataSource.titleHeaderSection = newValue.toTitleHeader

            // store new value
            _store.update(newValue)
        }
    }
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
