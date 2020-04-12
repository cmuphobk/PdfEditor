//
//  DrawConfigurationView.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit

protocol DrawConfigurationViewDelegate: class {
    func didTriggerColor()
    func didTriggerWidth(_ width: CGFloat)
    func didTriggerAlpha(_ alpha: CGFloat)
}

class DrawConfigurationView: UIView {

    // MARK: - Constants and Computed

    private let colorLabelText: String = "Цвет"
    private let widthLabelText: String = "Толщина"
    private let alphaLabelText: String = "Прозрачность"
    private let sliderWidth: CGFloat = 163.0
    private let buttonWidth: CGFloat = 16.0

    private let leftRightContentOffset: CGFloat = 24.0
    private let additionalButtonOffset: CGFloat = 32.0

    let arrowHeight: CGFloat = 12.0
    let arrowWidth: CGFloat = 5.0

    private let labelColor: UIColor = .black
    private let labelFont: UIFont = UIFont.systemFont(ofSize: 16.0)

    private let backgroundViewColor: UIColor = .white
    private let backgroundCornerRadius: CGFloat = 8.0

    // MARK: - UIElements

    lazy var colorLabel: UILabel = {
        let colorLabel = UILabel()
        colorLabel.text = colorLabelText
        colorLabel.textColor = labelColor
        colorLabel.font = labelFont

        return colorLabel
    }()

    lazy var colorPickerButton: UIButton = {
        let colorPickerButton = UIButton()
        colorPickerButton.setTitle("", for: .normal)

        colorPickerButton.backgroundColor = pickedColor
        colorPickerButton.layer.shadowColor = UIColor.lightGray.cgColor
        colorPickerButton.layer.shadowOpacity = 0.8
        colorPickerButton.layer.shadowOffset = .zero
        colorPickerButton.layer.shadowRadius = 10
        return colorPickerButton
    }()

    lazy var widthLabel: UILabel = {
        let widthLabel = UILabel()
        widthLabel.text = widthLabelText
        widthLabel.textColor = labelColor
        widthLabel.font = labelFont

        return widthLabel
    }()
    lazy var widthSlider: UISlider = {
        let widthSlider = UISlider()

        return widthSlider
    }()

    lazy var alphaLabel: UILabel = {
        let alphaLabel = UILabel()
        alphaLabel.text = alphaLabelText
        alphaLabel.textColor = labelColor
        alphaLabel.font = labelFont

        return alphaLabel
    }()
    lazy var alphaSlider: UISlider = {
        let alphaSlider = UISlider()

        return alphaSlider
    }()

    // MARK: - Stored

    weak var roundedLayer: CALayer?
    weak var arrowLayer: CALayer?

    private var privatePickedColor: UIColor?
    var pickedColor: UIColor {
        get {
            return privatePickedColor!
        }
        set {
            privatePickedColor = newValue
            
            setNeedsLayout()
            drawCircle()
            drawArrow()
        }
    }

    weak var delegate: DrawConfigurationViewDelegate?

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        pickedColor = .white
        setupInitialState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    private(set) var needCreateConstraints: Bool = true
    override func updateConstraints() {
        super.updateConstraints()

        if !needCreateConstraints {
            return
        }
        needCreateConstraints = false

        NSLayoutConstraint.activate([
            // Left
            colorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftRightContentOffset),
            widthLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftRightContentOffset),
            alphaLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftRightContentOffset),

            // Top
            colorLabel.topAnchor.constraint(equalTo: topAnchor, constant: 27.0),
            widthLabel.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 30.0),
            alphaLabel.topAnchor.constraint(equalTo: widthLabel.bottomAnchor, constant: 30.0),

            // Center
            colorPickerButton.centerYAnchor.constraint(equalTo: colorLabel.centerYAnchor),
            widthSlider.centerYAnchor.constraint(equalTo: widthLabel.centerYAnchor),
            alphaSlider.centerYAnchor.constraint(equalTo: alphaLabel.centerYAnchor),

            // Right
            colorPickerButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -leftRightContentOffset - additionalButtonOffset),
            widthSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -leftRightContentOffset),
            alphaSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -leftRightContentOffset),

            // Between
            colorLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: colorPickerButton.leadingAnchor,
                constant: -8.0
            ),
            widthLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: widthSlider.leadingAnchor,
                constant: -8.0
            ),
            alphaLabel.trailingAnchor.constraint(
                equalTo: alphaSlider.leadingAnchor,
                constant: -8.0
            ),

            // Width
            colorPickerButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            widthSlider.widthAnchor.constraint(equalToConstant: sliderWidth),
            alphaSlider.widthAnchor.constraint(equalToConstant: sliderWidth),

            // Height
            colorPickerButton.heightAnchor.constraint(equalToConstant: buttonWidth),

            // Bottom
            alphaLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -36.0)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        colorPickerButton.backgroundColor = privatePickedColor
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        layer.cornerRadius = backgroundCornerRadius

        colorPickerButton.layer.cornerRadius = buttonWidth * 0.5

        drawCircle()
        drawArrow()
    }

    private func setupInitialState() {
        backgroundColor = backgroundViewColor
        clipsToBounds = true

        addSubview(colorLabel)
        addSubview(colorPickerButton)
        addSubview(widthLabel)
        addSubview(widthSlider)
        addSubview(alphaLabel)
        addSubview(alphaSlider)

        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        colorPickerButton.translatesAutoresizingMaskIntoConstraints = false
        widthLabel.translatesAutoresizingMaskIntoConstraints = false
        widthSlider.translatesAutoresizingMaskIntoConstraints = false
        alphaLabel.translatesAutoresizingMaskIntoConstraints = false
        alphaSlider.translatesAutoresizingMaskIntoConstraints = false

        colorPickerButton.addTarget(self, action: #selector(didTriggerColorPickerButton(_:)), for: .touchDown)
        widthSlider.addTarget(self, action: #selector(didTriggerWidthSlider(_:)), for: .valueChanged)
        alphaSlider.addTarget(self, action: #selector(didTriggerAlphaSlider(_:)), for: .valueChanged)
    }

}

// MARK: - Actions

extension DrawConfigurationView {
    @objc private func didTriggerColorPickerButton(_ sender: UIButton) {
        self.delegate?.didTriggerColor()
    }

    @objc private func didTriggerWidthSlider(_ sender: UISlider) {
        self.delegate?.didTriggerWidth(CGFloat(sender.value))
    }

    @objc private func didTriggerAlphaSlider(_ sender: UISlider) {
        self.delegate?.didTriggerAlpha(CGFloat(sender.value))
    }
}


extension DrawConfigurationView {

    func drawCircle() {

        let rect = colorPickerButton.frame.insetBy(dx: -2.0, dy: -2.0)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.5)

        let newLayer = CAShapeLayer()
        newLayer.path = path.cgPath
        newLayer.fillColor = UIColor.clear.cgColor
        newLayer.strokeColor = pickedColor.cgColor

        roundedLayer?.removeFromSuperlayer()
        layer.addSublayer(newLayer)
        roundedLayer = newLayer
    }

    func drawArrow() {

        var rect = colorPickerButton.frame.offsetBy(dx: colorPickerButton.frame.width + additionalButtonOffset - arrowWidth,
                                                    dy: (colorPickerButton.frame.height - arrowHeight) / 2)
        rect.size = CGSize(width: arrowWidth, height: arrowHeight)

        let path = UIBezierPath()
        path.lineJoinStyle = CGLineJoin.round
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.lineWidth = 3.0

        let newLayer = CAShapeLayer()
        newLayer.path = path.cgPath
        newLayer.fillColor = UIColor.clear.cgColor
        newLayer.strokeColor = pickedColor.cgColor

        arrowLayer?.removeFromSuperlayer()
        layer.addSublayer(newLayer)
        arrowLayer = newLayer

    }

}
