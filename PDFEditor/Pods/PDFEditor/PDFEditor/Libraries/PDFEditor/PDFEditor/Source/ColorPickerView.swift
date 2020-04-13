//
//  ColorPickerView.swift
//  PDFEditor
//
//  Created by Кирилл on 30/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit

protocol ColorPickerViewDelegate: class {
    func didTriggerColorPicker(color: UIColor)
}

class ColorPickerView : UIView {

    // MARK: - Constants and Computed

    private let saturationExponentTop: CGFloat = 2.0
    private let saturationExponentBottom: CGFloat = 1.3
    private let backgroundCornerRadius: CGFloat = 8.0

    private let grayPaletteHeightFactor: CGFloat = 0.1

    private let offsetPallete: CGFloat = 8.0

    // MARK: - UIElements

    // MARK: - Stored

    weak var delegate: ColorPickerViewDelegate?

    private(set) var rectForDraw: CGRect!
    private var rectGrayPalette = CGRect.zero
    private var rectMainPalette = CGRect.zero

    private(set) var elementSize: CGFloat = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInitailState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let color = getColorAtPoint(point: location)
        delegate?.didTriggerColorPicker(color: color)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let color = getColorAtPoint(point: location)
        delegate?.didTriggerColorPicker(color: color)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let color = getColorAtPoint(point: location)
        delegate?.didTriggerColorPicker(color: color)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        self.layer.cornerRadius = backgroundCornerRadius

        guard let context = UIGraphicsGetCurrentContext() else { return }

        let rect = rect.insetBy(dx: offsetPallete, dy: offsetPallete)
        rectForDraw = rect

        rectGrayPalette = CGRect(x: rect.minX,
                                 y: rect.minY,
                                 width: rect.width,
                                 height: rect.height * grayPaletteHeightFactor)

        rectMainPalette = CGRect(x: rect.minX,
                                 y: rectGrayPalette.maxY,
                                 width: rect.width,
                                 height: rect.height - rectGrayPalette.height)

        // gray palette
        for y in stride(
            from: rect.minY,
            to: rectGrayPalette.height,
            by: elementSize
            ) {

                for x in stride(
                    from: rect.minX,
                    to: rectGrayPalette.width,
                    by: elementSize
                    ) {

                        let hue: CGFloat = x / rectGrayPalette.width

                        let color = UIColor(white: hue, alpha: 1.0)

                        context.setFillColor(color.cgColor)

                        let fillRect = CGRect(x: x,
                                              y: y,
                                              width: elementSize,
                                              height: elementSize)
                        context.fill(fillRect)
                }
        }

        // main palette
        for y in stride(
            from: rect.minY,
            to: rectMainPalette.height,
            by: elementSize
            ) {

                var saturation: CGFloat!
                if y < rectMainPalette.height / 2.0 {
                    saturation = 2 * y / rectMainPalette.height
                } else {
                    saturation = 2.0 * (rectMainPalette.height - y) / rectMainPalette.height
                }

                saturation = pow(saturation, y < rectMainPalette.height / 2.0 ? saturationExponentTop : saturationExponentBottom)

                let brightness: CGFloat!
                if y < rectMainPalette.height / 2.0 {
                    brightness = 1.0
                } else {
                    brightness = 2.0 * (rectMainPalette.height - y) / rectMainPalette.height
                }

                for x in stride(
                    from: rect.minX,
                    to: rectMainPalette.width,
                    by: elementSize
                    ) {

                        let hue = x / rectMainPalette.width

                        let color = UIColor(
                            hue: hue,
                            saturation: saturation,
                            brightness: brightness,
                            alpha: 1.0
                        )

                        context.setFillColor(color.cgColor)

                        let fillRect = CGRect(
                            x: x,
                            y: y + rectMainPalette.origin.y,
                            width: elementSize,
                            height: elementSize
                        )
                        context.fill(fillRect)
                }
        }
    }
}

// MARK: - Actions

extension ColorPickerView {




}

// MARK: - Private

extension ColorPickerView {

    private func setupInitailState() {
        clipsToBounds = true
        backgroundColor = .white

    }

    private func getColorAtPoint(point: CGPoint) -> UIColor {

        var roundedPoint = CGPoint(x: elementSize * CGFloat(Int(point.x / elementSize)),
                                   y: elementSize * CGFloat(Int(point.y / elementSize)))

        let hue = roundedPoint.x / rectForDraw.width

        if rectMainPalette.contains(point) {
            // main palette -> offset point, because rectMainPalette.origin.y is not 0
            roundedPoint.y -= rectMainPalette.origin.y

            var saturation: CGFloat!
            if roundedPoint.y < rectMainPalette.height / 2.0 {
                saturation = (2 * roundedPoint.y) / rectMainPalette.height
            } else {
                saturation = 2.0 * (rectMainPalette.height - roundedPoint.y) / rectMainPalette.height
            }

            saturation = pow(saturation, roundedPoint.y < rectMainPalette.height / 2.0 ? saturationExponentTop : saturationExponentBottom)

            let brightness: CGFloat!
            if roundedPoint.y < rectMainPalette.height / 2.0 {
                brightness = 1.0
            } else {
                brightness = 2.0 * (rectMainPalette.height - roundedPoint.y) / rectMainPalette.height
            }

            return UIColor(hue: hue,
                           saturation: saturation,
                           brightness: brightness,
                           alpha: 1.0)
        } else {
            // gray palette
            return UIColor(white: hue,
                           alpha: 1.0)
        }
    }

}
