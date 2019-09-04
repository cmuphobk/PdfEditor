//
//  InstrumentTableViewCell.swift
//  PDFEditor
//
//  Created by Кирилл on 03/09/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit

class InstrumentTableViewCell: UITableViewCell {

    // MARK: - Initialize

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = {
            let bgview = UIView()
            let color = UIColor.lightGray.withAlphaComponent(0.3)
            bgview.backgroundColor = color
            bgview.clipsToBounds = true
            return bgview
        }()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        let offset: CGFloat = 6.0
        let width = frame.size.width - offset
        let rect = CGRect(x: bounds.minX + (offset / 2.0),
                          y: (bounds.height - width) / 2.0,
                          width: width,
                          height: width)
        self.selectedBackgroundView?.frame = rect
        self.imageView?.frame = rect.insetBy(dx: rect.width / 4.0, dy: rect.height / 4.0)

    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let offset: CGFloat = 4.0
        let width = frame.size.width - offset
        self.selectedBackgroundView?.layer.cornerRadius = width * 0.5

    }

}
