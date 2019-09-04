//
//  PDFEditView.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit
import PDFKit

enum DrawingTool: Int {
    case pen = 0
    case eraser = 1
    case disable = 2
}

class PDFEditView: UIView {

    // MARK: - Constants and Computed

    private let viewInstrumentsWidth: CGFloat = 60.0
    private let viewThumbnailPDFHeight: CGFloat = 100.0
    private var viewInstrumentsOffsetLeft: CGFloat = 40.0
    private var viewInstrumentsOffsetTop: CGFloat = 40.0
    private var colorPickerHeight: CGFloat = 300.0
    private var drawingWidthDivider: CGFloat = 50.0

    private var viewInstrumentsHeight: CGFloat {
        return CGFloat(buttonViewModelArray.count) * viewInstrumentsWidth
    }

    // MARK: - UIElements

    lazy var pdfView: PDFView = {
        let pdfView = PDFView()
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.delegate = self
        return pdfView
    }()

    lazy var thumbnailView: PDFThumbnailView = {
        let thumbnailView = PDFThumbnailView()
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: viewThumbnailPDFHeight,
                                             height: viewThumbnailPDFHeight)
        thumbnailView.layoutMode = .horizontal

        thumbnailView.backgroundColor = UIColor(red: 234.0/255.0, green: 234.0/255.0, blue: 234.0/255.0, alpha: 1.0)
        thumbnailView.layer.shadowColor = UIColor.lightGray.cgColor
        thumbnailView.layer.shadowOpacity = 0.5
        thumbnailView.layer.shadowOffset = .zero
        thumbnailView.layer.shadowRadius = 10

        return thumbnailView
    }()

    lazy var instrumentsShadowLayer: CALayer = {
        let instrumentsShadowLayer = CALayer()
        instrumentsShadowLayer.backgroundColor = UIColor.white.cgColor
        instrumentsShadowLayer.shadowColor = UIColor.lightGray.cgColor
        instrumentsShadowLayer.shadowOpacity = 0.8
        instrumentsShadowLayer.shadowOffset = .zero
        instrumentsShadowLayer.shadowRadius = 10
        instrumentsShadowLayer.cornerRadius = instrumentsView.cornerRadius

        return instrumentsShadowLayer
    }()


    lazy var instrumentsView: InstrumentsView = {
        let instrumentsView = InstrumentsView()
        if let index = buttonViewModelArray.firstIndex(where: {$0.isSelected == true}) {
            instrumentsView.tableView.selectRow(at: IndexPath(row: index, section: 0),
                                                animated: true,
                                                scrollPosition: .none)
        }
        return instrumentsView
    }()

    lazy var drawConfigurationView: DrawConfigurationView = {
        let drawConfigurationView = DrawConfigurationView()
        drawConfigurationView.pickedColor = drawingColor
        drawConfigurationView.isHidden = true
        drawConfigurationView.delegate = self
        drawConfigurationView.alphaSlider.value = Float(drawingAlpha)
        drawConfigurationView.widthSlider.value = Float(drawingWidth / drawingWidthDivider)
        return drawConfigurationView
    }()

    lazy var colorPickerView: ColorPickerView = {
        let colorPickerView = ColorPickerView()
        colorPickerView.delegate = self
        colorPickerView.isHidden = true
        return colorPickerView
    }()

    // MARK: - Stored

    var document: PDFDocument! {
        get {
            return pdfView.document
        }
        set {
            pdfView.document = newValue

            if !thumbnailView.isDescendant(of: self) {
                addSubview(thumbnailView)
            }

        }
    }

    lazy var pencil = InstrumentsButtonViewModel(index: 0,
                                            image: getImage(with: "pencil"),
                                            tintColor: .black,
                                            isSelected: false)

    lazy var erase = InstrumentsButtonViewModel(index: 1,
                                           image: getImage(with: "erase"),
                                           tintColor: .black,
                                           isSelected: false)

    lazy var arrow_left = InstrumentsButtonViewModel(index: 2,
                                                image: getImage(with: "arrow_left"),
                                                tintColor: .black,
                                                isSelected: false)

    lazy var arrow_right = InstrumentsButtonViewModel(index: 3,
                                                 image: getImage(with: "arrow_right"),
                                                 tintColor: .lightGray,
                                                 isSelected: false)

    lazy var color_pick = InstrumentsButtonViewModel(index: 4,
                                                image: getImage(with: "color_pick"),
                                                tintColor: drawingColor,
                                                isSelected: false)

    lazy var buttonViewModelArray = [
        pencil,
        erase,
        arrow_left,
        arrow_right,
        color_pick
    ]

    lazy var drawingGestureRecognizer: DrawingGestureRecognizer = {
        let drawingGestureRecognizer = DrawingGestureRecognizer()
        drawingGestureRecognizer.drawingDelegate = self
        return drawingGestureRecognizer
    }()

    private(set) var lastRemovedAnnotations: [PDFAnnotation] = [] {
        didSet {
            let tintColor: UIColor = lastRemovedAnnotations.count > 0 ? .black : .lightGray
            buttonViewModelArray = buttonViewModelArray.map {
                if $0.index == arrow_right.index  {
                    var model = $0
                    model.tintColor = tintColor
                    return model
                }
                return $0
            }
            instrumentsView.reloadData()
        }
    }

    private(set) var drawingTool: DrawingTool = .disable {
        didSet {
            if drawingTool == .disable {
                pdfView.removeGestureRecognizer(drawingGestureRecognizer)
            } else {
                pdfView.addGestureRecognizer(drawingGestureRecognizer)
            }
        }
    }
    private(set) var drawingColor: UIColor = .red {
        didSet {
            buttonViewModelArray = buttonViewModelArray.map {
                if $0.index == color_pick.index  {
                    var model = $0
                    model.tintColor = drawingColor
                    return model
                }
                return $0
            }
            instrumentsView.reloadData()
        }
    }
    private(set) var drawingWidth: CGFloat = 15
    private(set) var drawingAlpha: CGFloat = 1

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupInitialState()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let sublayers = layer.sublayers, !sublayers.contains(instrumentsShadowLayer) {
            layer.insertSublayer(instrumentsShadowLayer, below: instrumentsView.layer)
        }

        instrumentsShadowLayer.frame = CGRect(x: viewInstrumentsOffsetLeft,
                                              y: viewInstrumentsOffsetTop,
                                              width: viewInstrumentsWidth,
                                              height: viewInstrumentsHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        pdfView.frame = CGRect(x: 0.0,
                               y: 0.0,
                               width: bounds.width,
                               height: bounds.height)

        instrumentsView.frame = CGRect(x: viewInstrumentsOffsetLeft,
                                       y: viewInstrumentsOffsetTop,
                                       width: viewInstrumentsWidth,
                                       height: viewInstrumentsHeight)

        instrumentsView.delegate = self

        thumbnailView.frame = CGRect(x: 0.0,
                                     y: bounds.height - viewThumbnailPDFHeight,
                                     width: bounds.width,
                                     height: viewThumbnailPDFHeight)

    }

    private(set) var needCreateConstraints: Bool = true
    override func updateConstraints() {
        super.updateConstraints()

        if !needCreateConstraints {
            return
        }
        needCreateConstraints = false

        NSLayoutConstraint.activate([
            drawConfigurationView.topAnchor.constraint(equalTo: instrumentsView.bottomAnchor, constant: -viewInstrumentsWidth),
            drawConfigurationView.leadingAnchor.constraint(equalTo: instrumentsView.trailingAnchor, constant: 8.0),
            drawConfigurationView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0.0),
            drawConfigurationView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -8.0),
            drawConfigurationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0.0),

            colorPickerView.topAnchor.constraint(equalTo: drawConfigurationView.colorPickerButton.bottomAnchor, constant: 8.0),
            colorPickerView.trailingAnchor.constraint(equalTo: drawConfigurationView.trailingAnchor, constant: 0.0),
            colorPickerView.widthAnchor.constraint(equalTo: drawConfigurationView.widthAnchor, constant: 0.0),
            colorPickerView.heightAnchor.constraint(equalToConstant: colorPickerHeight)
        ])
    }
}

// MARK: - ColorPickerViewDelegate

extension PDFEditView: ColorPickerViewDelegate {

    func didTriggerColorPicker(color: UIColor) {
        drawConfigurationView.pickedColor = color
        drawingColor = color
    }

}

// MARK: - DrawConfigurationViewDelegate

extension PDFEditView: DrawConfigurationViewDelegate {

    func didTriggerColor() {
        colorPickerView.isHidden = !colorPickerView.isHidden
        colorPickerView.setNeedsDisplay()
    }

    func didTriggerWidth(_ width: CGFloat) {
        drawingWidth = width * drawingWidthDivider
    }

    func didTriggerAlpha(_ alpha: CGFloat) {
        drawingAlpha = alpha
    }

}

// MARK: - InstrumentsViewDelegate

extension PDFEditView: InstrumentsViewDelegate {
    func buttonsForInstruments() -> [InstrumentsButtonViewModel] {
        return buttonViewModelArray
    }

    func didTriggerButton(at index: Int, type: TriggerType) {

        buttonViewModelArray = buttonViewModelArray.enumerated().map { (arg) -> InstrumentsButtonViewModel in
            var (key, model) = arg

            switch type {
            case .select:
                model.updateIsSelected(key == index)
            case .deselect:
                model.updateIsSelected(false)
            }

            return model
        }

        drawConfigurationView.isHidden = true
        colorPickerView.isHidden = true

        if type == .deselect {
            drawingTool = .disable
            return
        }

        if index == pencil.index {
            drawingTool = .pen
            lastRemovedAnnotations = []
        } else if index == erase.index {
            drawingTool = .eraser
            lastRemovedAnnotations = []
        } else if index == arrow_left.index {
            drawingTool = .disable
            guard let page = pdfView.currentPage else { return }
            guard let last = page.annotations.last else { return }
            lastRemovedAnnotations.append(last)
            page.removeAnnotation(last)
        } else if index == arrow_right.index {
            drawingTool = .disable
            guard let page = pdfView.currentPage else { return }
            guard let last = lastRemovedAnnotations.last else { return }
            lastRemovedAnnotations.removeLast()
            page.addAnnotation(last)
        } else if index == color_pick.index {
            drawingTool = .disable
            drawConfigurationView.isHidden = false
            drawConfigurationView.setNeedsDisplay()
        }
    }
}

// MARK: - DrawingGestureRecognizerDelegate

extension PDFEditView: DrawingGestureRecognizerDelegate {

    func drawingBegan(_ location: CGPoint) {

        if drawingTool == .disable {
            return
        }

        if drawingTool == .eraser {
            return
        }

        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }
        let convertedPoint = pdfView.convert(location,
                                             to: page)

        // Создаем и сохраняем path
        let pathRect = CGRect(x: convertedPoint.x, y: convertedPoint.y, width: 0, height: 0)
        let path = UIBezierPath(ovalIn: pathRect)

        //Создаем и сохраняем аннотацию
        let annotation = createAnnotation(page: page,
                                          bounds: page.bounds(for: pdfView.displayBox),
                                          color: drawingColor,
                                          width: drawingWidth,
                                          alpha: drawingAlpha)
        annotation.add(path)
        page.addAnnotation(annotation)
    }

    func drawingMoved(_ location: CGPoint) {
        if drawingTool == .disable {
            return
        }
        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }
        let convertedPoint = pdfView.convert(location,
                                             to: page)

        if drawingTool == .eraser {
            eraseAnnotationAtPoint(point: convertedPoint,
                                    page: page)
            return
        }

        addLine(on: page, to: convertedPoint)
    }

    func drawingEnded(_ location: CGPoint) {
        if drawingTool == .disable {
            return
        }
        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }
        let convertedPoint = pdfView.convert(location,
                                             to: page)

        if drawingTool == .eraser {
            eraseAnnotationAtPoint(point: convertedPoint,
                                    page: page)
            return
        }

        addLine(on: page, to: convertedPoint)
    }
}

// MARK: - PDFViewDelegate

extension PDFEditView: PDFViewDelegate {

    func pdfViewPerformGo(toPage sender: PDFView) {
        lastRemovedAnnotations = []
    }

}

// MARK: - Private

extension PDFEditView {

    private func setupInitialState() {

        addSubview(pdfView)

        addSubview(instrumentsView)

        addSubview(drawConfigurationView)
        addSubview(colorPickerView)

        drawConfigurationView.translatesAutoresizingMaskIntoConstraints = false
        colorPickerView.translatesAutoresizingMaskIntoConstraints = false

    }

    private func createAnnotation(page: PDFPage,
                                  bounds: CGRect,
                                  color: UIColor,
                                  width: CGFloat,
                                  alpha: CGFloat) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = width

        let annotation = PDFAnnotation(bounds: bounds,
                                       forType: .ink,
                                       withProperties: nil)
        annotation.color = color.withAlphaComponent(alpha)
        annotation.border = border
        return annotation
    }

    private func eraseAnnotationAtPoint(point: CGPoint,
                                        page: PDFPage) {
        for annotation in page.annotations {
            annotation.removePath(at: point)
        }
    }

    private func addLine(on page: PDFPage, to point: CGPoint) {
        guard let annotation = page.annotations.last else { return }
        guard let oldBezierPath = annotation.paths?.last else { return }
        guard let newBezierPath = oldBezierPath.copy() as? UIBezierPath else { return }

        //Перерисовываем annotation с новым path
        newBezierPath.addLine(to: point)
        
        annotation.remove(oldBezierPath)
        annotation.add(newBezierPath)
    }

    private func getImage(with name: String) -> UIImage {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
    }

}
