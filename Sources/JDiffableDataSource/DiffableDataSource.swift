//
//  File.swift
//  
//
//  Created by TruongGiang on 21/01/2022.
//

import UIKit
import Combine

public final class JTableViewDiffableDataSource<I: JItemable> {

    // MARK: - Typealias
    public typealias CellProvider = (UITableView, IndexPath, I) -> UITableViewCell
    public typealias Snapshot = NSDiffableDataSourceSnapshot<AnySection<I>, I.ID>

    // MARK: - Private Properties
    private var _dataSource: JDataSource<I>!
    private var _store = JStore<I>()
    private var _cancellables = Set<AnyCancellable>()

    var snapshotPublisher: SnapshotPublisher {
        return .init(store: _store)
    }

    // MARK: - Initializer
    public init(
        tableView: UITableView,
        cellProvider: @escaping (UITableView, IndexPath, I) -> UITableViewCell
    ) {
        self._dataSource = JDataSource<I>(
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

public class JDataSource<I: JItemable>: UITableViewDiffableDataSource<AnySection<I>, I.ID> {

    var titleHeaderSection: TitleHeaderSection? = nil

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleHeaderSection?(section)
    }
}

// MARK: - Computed Properties
extension JTableViewDiffableDataSource {

    private var _sections: [AnySection<I>] {
        get { _store.sections }
        set {
            // Update title header for datasource
            _dataSource.titleHeaderSection = newValue.toTitleHeader

            // store new value
            _store.update(newValue)
        }
    }

    ///  Use this func when your tableview have multiple sections
    public func update<S: JSectiontable>(_ sections: [S]) where I == S.Item {
        self._sections = sections.map(AnySection.init)
    }

    ///  Use this func when your tableview have single sections
    ///  This func will define default section, just assign items to params only
    public func update(_ items: [I]) {
        let defaultSection = DefaultSection.main(items: items)
        self._sections = [AnySection<I>(defaultSection)]
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
