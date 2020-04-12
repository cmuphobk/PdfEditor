//
//  PDFView+DisableSelection.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import PDFKit

extension PDFView {

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override open func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }

        super.addGestureRecognizer(gestureRecognizer)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        subviews.first?.backgroundColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    }
}
