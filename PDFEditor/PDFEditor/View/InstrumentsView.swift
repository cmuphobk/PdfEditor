//
//  InstrumentsView.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit

enum TriggerType {
    case select
    case deselect
}

protocol InstrumentsViewDelegate: class {
    func buttonsForInstruments() -> [InstrumentsButtonViewModel]
    func didTriggerButton(at index: Int, type: TriggerType)
}

struct InstrumentsButtonViewModel {
    let index: Int
    var image: UIImage
    var tintColor: UIColor
    var isSelected: Bool

    mutating func updateIsSelected(_ IsSelected: Bool) {
        self.isSelected = IsSelected
    }
}

class InstrumentsView: UIView {

    // MARK: - Constants and Computed

    private let cellIdentifier = "InstrumentsCell"

    // MARK: - UIElements

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        return tableView
    }()

    // MARK: - Stored

    weak var delegate: InstrumentsViewDelegate?
    let cornerRadius: CGFloat = 5.0

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        tableView.frame = bounds

        if !tableView.isDescendant(of: self) {
            addSubview(tableView)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = cornerRadius
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.5
        layer.masksToBounds = true
    }

    // MARK: - Public

    func reloadData() {
        self.tableView.reloadData()
    }

}

// MARK: - UITableViewDataSource

extension InstrumentsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.buttonsForInstruments().count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = InstrumentTableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        if let buttonsForInstruments = delegate?.buttonsForInstruments() {
            let model = buttonsForInstruments[indexPath.row]
            cell.imageView?.image = model.image
            cell.imageView?.contentMode = .scaleAspectFit
            cell.imageView?.tintColor = model.tintColor

            cell.imageView?.layer.shadowColor = UIColor.lightGray.cgColor
            cell.imageView?.layer.shadowOpacity = 0.8
            cell.imageView?.layer.shadowOffset = .zero
            cell.imageView?.layer.shadowRadius = 10

            if model.isSelected {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension InstrumentsView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return frame.width
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let selectedIndex = delegate?.buttonsForInstruments().firstIndex(where: { (model) -> Bool in
            return model.isSelected
        })

        if selectedIndex == indexPath.row {
            tableView.deselectRow(at: indexPath, animated: true)
            delegate?.didTriggerButton(at: indexPath.row, type: .deselect)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTriggerButton(at: indexPath.row, type: .select)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        delegate?.didTriggerButton(at: indexPath.row, type: .deselect)
    }

}
