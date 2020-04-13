//
//  PDFEditView.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit
import PDFKit

public enum DrawingTool: Int {
    case pen = 0
    case text = 1
    case eraser = 2
    case disable = 3
}

public class PDFEditView: UIView {

    // MARK: - Constants and Computed

    private let viewInstrumentsWidth: CGFloat = 60.0
    private let viewThumbnailPDFHeight: CGFloat = 100.0
    private var viewInstrumentsOffsetLeft: CGFloat = 40.0
    private var viewInstrumentsOffsetTop: CGFloat = 40.0
    private var colorPickerHeight: CGFloat = 300.0
    private var drawingWidthDivider: CGFloat = 50.0

    private let currentTextAnnotationMinWidth: CGFloat = 150.0

    private var viewInstrumentsHeight: CGFloat {
        return CGFloat(buttonViewModelArray.count) * viewInstrumentsWidth
    }

    // MARK: - UIElements

    private lazy var pdfView: PDFView = {
        let pdfView = PDFView()
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal

        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: .PDFViewPageChanged, object: nil)

        currentPage = pdfView.currentPage

//        pdfView.addGestureRecognizer(tapGestureRecognizer)

        return pdfView
    }()

    @objc private func handlePageChange(notification: Notification) {
        lastRemovedAnnotations = []

        // FIXME: - duplicate
        if let page = currentPage, let currentTextAnnotation = currentTextAnnotation {
            page.removeAnnotation(currentTextAnnotation)
            let appearance = PDFAppearanceCharacteristics()
            currentTextAnnotation.setValue(appearance, forAnnotationKey: .widgetAppearanceDictionary)
            page.addAnnotation(currentTextAnnotation)
        }
        currentTextAnnotation = nil

        currentPage = pdfView.currentPage

        drawingTool = .disable
    }

    private lazy var thumbnailView: PDFThumbnailView = {
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

    private lazy var instrumentsShadowLayer: CALayer = {
        let instrumentsShadowLayer = CALayer()
        instrumentsShadowLayer.backgroundColor = UIColor.white.cgColor
        instrumentsShadowLayer.shadowColor = UIColor.lightGray.cgColor
        instrumentsShadowLayer.shadowOpacity = 0.8
        instrumentsShadowLayer.shadowOffset = .zero
        instrumentsShadowLayer.shadowRadius = 10
        instrumentsShadowLayer.cornerRadius = instrumentsView.cornerRadius

        return instrumentsShadowLayer
    }()


    private lazy var instrumentsView: InstrumentsView = {
        let instrumentsView = InstrumentsView()
        if let index = buttonViewModelArray.firstIndex(where: {$0.isSelected == true}) {
            instrumentsView.tableView.selectRow(at: IndexPath(row: index, section: 0),
                                                animated: true,
                                                scrollPosition: .none)
        }
        return instrumentsView
    }()

    private lazy var drawConfigurationView: DrawConfigurationView = {
        let drawConfigurationView = DrawConfigurationView()
        drawConfigurationView.pickedColor = drawingColor
        drawConfigurationView.isHidden = true
        drawConfigurationView.delegate = self
        drawConfigurationView.alphaSlider.value = Float(drawingAlpha)
        drawConfigurationView.widthSlider.value = Float(drawingWidth / drawingWidthDivider)
        return drawConfigurationView
    }()

    private lazy var colorPickerView: ColorPickerView = {
        let colorPickerView = ColorPickerView()
        colorPickerView.delegate = self
        colorPickerView.isHidden = true
        return colorPickerView
    }()

    // MARK: - Stored
    
    public var document: PDFDocument! {
        get {
            return pdfView.document
        }
        set {
            pdfView.document = newValue
            currentPage = pdfView.currentPage

            if !thumbnailView.isDescendant(of: self) {
                addSubview(thumbnailView)
            }

        }
    }

    private lazy var pencil = InstrumentsButtonViewModel(index: 0,
                                                 image: getImage(with: "pencil"),
                                                 tintColor: .black,
                                                 isSelected: false)

    private lazy var text = InstrumentsButtonViewModel(index: 1,
                                               image: getImage(with: "text"),
                                               tintColor: .black,
                                               isSelected: false)

    private lazy var erase = InstrumentsButtonViewModel(index: 2,
                                                image: getImage(with: "erase"),
                                                tintColor: .black,
                                                isSelected: false)

    private lazy var arrow_left = InstrumentsButtonViewModel(index: 3,
                                                     image: getImage(with: "arrow_left"),
                                                     tintColor: .black,
                                                     isSelected: false)

    private lazy var arrow_right = InstrumentsButtonViewModel(index: 4,
                                                      image: getImage(with: "arrow_right"),
                                                      tintColor: .lightGray,
                                                      isSelected: false)

    private lazy var color_pick = InstrumentsButtonViewModel(index: 5,
                                                     image: getImage(with: "color_pick"),
                                                     tintColor: drawingColor,
                                                     isSelected: false)

    private lazy var trash = InstrumentsButtonViewModel(index: 6,
                                                image: getImage(with: "trash"),
                                                tintColor: .black,
                                                isSelected: false)

    private lazy var buttonViewModelArray = [
        pencil,
        text,
        erase,
        arrow_left,
        arrow_right,
        color_pick,
        trash
    ]

    private lazy var drawingGestureRecognizer: DrawingGestureRecognizer = {
        let drawingGestureRecognizer = DrawingGestureRecognizer()
        drawingGestureRecognizer.drawingDelegate = self
        return drawingGestureRecognizer
    }()

//    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
//        let tapGestureRecognizer = UITapGestureRecognizer()
//        tapGestureRecognizer.delegate = self
//        return tapGestureRecognizer
//    }()

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()

    private lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        pinchGestureRecognizer.delegate = self
        return pinchGestureRecognizer
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

    private(set) var currentTextAnnotation: PDFAnnotation!
    private(set) var currentTextAnnotationMinHeight: CGFloat = 30.0

    private(set) var currentPage: PDFPage!

    private(set) var drawingTool: DrawingTool = .disable {
        didSet {

            // FIXME: - to method
            pdfView.removeGestureRecognizer(panGestureRecognizer)
            pdfView.removeGestureRecognizer(pinchGestureRecognizer)
            pdfView.addGestureRecognizer(drawingGestureRecognizer)

            // FIXME: - duplicate
            if let page = currentPage, let currentTextAnnotation = currentTextAnnotation {
                page.removeAnnotation(currentTextAnnotation)
                let appearance = PDFAppearanceCharacteristics()
                currentTextAnnotation.setValue(appearance, forAnnotationKey: .widgetAppearanceDictionary)
                page.addAnnotation(currentTextAnnotation)
            }
            currentTextAnnotation = nil

            if drawingTool == .disable {

                buttonViewModelArray = buttonViewModelArray.map {
                    var newModel = $0
                    newModel.isSelected = false
                    return newModel
                }

                pdfView.removeGestureRecognizer(drawingGestureRecognizer)
//                pdfView.addGestureRecognizer(tapGestureRecognizer)
            } else {
                pdfView.addGestureRecognizer(drawingGestureRecognizer)
//                pdfView.removeGestureRecognizer(tapGestureRecognizer)
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

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let sublayers = layer.sublayers, !sublayers.contains(instrumentsShadowLayer) {
            layer.insertSublayer(instrumentsShadowLayer, below: instrumentsView.layer)
        }

        instrumentsShadowLayer.frame = CGRect(x: viewInstrumentsOffsetLeft,
                                              y: viewInstrumentsOffsetTop,
                                              width: viewInstrumentsWidth,
                                              height: viewInstrumentsHeight)
    }

    override public func layoutSubviews() {
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
    override public func updateConstraints() {
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

    func didTriggerButton(at model: InstrumentsButtonViewModel, type: TriggerType) {

        buttonViewModelArray = buttonViewModelArray.enumerated().map { (arg) -> InstrumentsButtonViewModel in
            var (key, value) = arg

            switch type {
            case .select:
                value.updateIsSelected(key == model.index)
            case .deselect:
                value.updateIsSelected(false)
            }

            return value
        }

        drawConfigurationView.isHidden = true
        colorPickerView.isHidden = true

        if type == .deselect {
            drawingTool = .disable
            return
        }

        if model.index == pencil.index {
            drawingTool = .pen
            lastRemovedAnnotations = []
        } else if model.index == text.index {
            drawingTool = .text
            lastRemovedAnnotations = []
        } else if model.index == erase.index {
            drawingTool = .eraser
            lastRemovedAnnotations = []
        } else if model.index == arrow_left.index {
            drawingTool = .disable
            guard let page = currentPage else { return }
            guard let last = page.annotations.last else { return }
            lastRemovedAnnotations.append(last)
            page.removeAnnotation(last)
        } else if model.index == arrow_right.index {
            drawingTool = .disable
            guard let page = currentPage else { return }
            guard let last = lastRemovedAnnotations.last else { return }
            lastRemovedAnnotations.removeLast()
            page.addAnnotation(last)
        } else if model.index == color_pick.index {
            drawingTool = .disable
            drawConfigurationView.isHidden = false
            drawConfigurationView.setNeedsDisplay()
        } else if model.index == trash.index {
            guard let page = currentPage else { return }
            for annotation in page.annotations.reversed() {
                page.removeAnnotation(annotation)
                lastRemovedAnnotations.append(annotation)
            }
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

        if drawingTool == .pen {

            // Создаем и сохраняем path
            let pathRect = CGRect(x: convertedPoint.x, y: convertedPoint.y, width: 0, height: 0)
            let path = UIBezierPath(ovalIn: pathRect)

            //Создаем и сохраняем аннотацию
            let annotation = createDrawAnnotation(page: page,
                                                  bounds: page.bounds(for: pdfView.displayBox),
                                                  color: drawingColor,
                                                  width: drawingWidth,
                                                  alpha: drawingAlpha)
            annotation.add(path)
            page.addAnnotation(annotation)
            return
        }
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

        if drawingTool == .pen {
            addLine(on: page, to: convertedPoint)
            return
        }
    }

    func drawingEnded(_ location: CGPoint) {
        if drawingTool == .disable {
            return
        }

        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }
        let convertedPoint = pdfView.convert(location,
                                             to: page)

        if drawingTool == .text {

            currentTextAnnotationMinHeight = drawingWidth + 8.0

            let annotation = createTextAnnotation(page: page,
                                                  bounds: CGRect(x: convertedPoint.x,
                                                                 y: convertedPoint.y,
                                                                 width: currentTextAnnotationMinWidth,
                                                                 height: currentTextAnnotationMinHeight),
                                                  color: drawingColor,
                                                  width: drawingWidth,
                                                  alpha: drawingAlpha)
            page.addAnnotation(annotation)
            lastRemovedAnnotations = []

            // FIXME: - to method
            pdfView.removeGestureRecognizer(drawingGestureRecognizer)
            pdfView.addGestureRecognizer(panGestureRecognizer)
            pdfView.addGestureRecognizer(pinchGestureRecognizer)

            currentTextAnnotation = annotation

            return
        }

        if drawingTool == .eraser {
            eraseAnnotationAtPoint(point: convertedPoint,
                                    page: page)
            return
        }

        if drawingTool == .pen {
            addLine(on: page, to: convertedPoint)
            return
        }
    }
}

// MARK: - UIPanGestureRecognizer

extension PDFEditView {

    @objc func pan(_ sender: UIPanGestureRecognizer) {
        if currentTextAnnotation == nil {
            return
        }
        if sender.state == .ended {
            return
        }

        let translation = sender.translation(in: sender.view)
        let location = sender.location(in: sender.view)

        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }

        page.removeAnnotation(currentTextAnnotation)
        currentTextAnnotation.bounds = currentTextAnnotation.bounds.offsetBy(dx: translation.x, dy: -translation.y)
        page.addAnnotation(currentTextAnnotation)

        sender.setTranslation(.zero, in: sender.view)
    }

}

// MARK: - UIPinchGestureRecognizer

extension PDFEditView {

    @objc func pinch(_ sender: UIPinchGestureRecognizer) {
        if currentTextAnnotation == nil {
            return
        }
        if sender.state == .ended || sender.numberOfTouches < 2 {
            return
        }

        let location = sender.location(in: sender.view)
        guard let page = pdfView.page(for: location,
                                      nearest: true) else { return }

        page.removeAnnotation(currentTextAnnotation)

        let dx = currentTextAnnotation.bounds.width * sender.scale - currentTextAnnotation.bounds.width
        let dy = currentTextAnnotation.bounds.height * sender.scale - currentTextAnnotation.bounds.height

        let width = currentTextAnnotation.bounds.width + dx
        let newWidth = width < currentTextAnnotationMinWidth ? currentTextAnnotationMinWidth : width

        let height = currentTextAnnotation.bounds.height + dy
        let newHeight = height < currentTextAnnotationMinHeight ? currentTextAnnotationMinHeight : height

        let touch1 = sender.location(ofTouch: 0, in: sender.view)
        let touch2 = sender.location(ofTouch: 1, in: sender.view)

        let deltaTouchX = abs( touch1.x - touch2.x )
        let deltaTouchY = abs( touch1.y - touch2.y )
        let ratio = deltaTouchX / deltaTouchY

        let horizontal = deltaTouchY == 0 || ratio > 2
        let vertical = deltaTouchX == 0 || ratio < 0.5

        if horizontal || vertical {
            currentTextAnnotation.bounds = CGRect(x: currentTextAnnotation.bounds.origin.x,
                                                  y: currentTextAnnotation.bounds.origin.y,
                                                  width: horizontal ? newWidth : currentTextAnnotation.bounds.width,
                                                  height: vertical ? newHeight : currentTextAnnotation.bounds.height)
        } else {
            currentTextAnnotation.bounds = CGRect(x: currentTextAnnotation.bounds.origin.x,
                                                  y: currentTextAnnotation.bounds.origin.y,
                                                  width: newWidth,
                                                  height: newHeight)
        }

        page.addAnnotation(currentTextAnnotation)

        sender.scale = 1.0
    }

}

// MARK: - UIGestureRecognizerDelegate

extension PDFEditView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer is UITapGestureRecognizer {
//            return true
//        }
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UISwipeGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
//        if gestureRecognizer is UITapGestureRecognizer && String(describing: type(of: otherGestureRecognizer)) == "UIScrollViewPanGestureRecognizer" {
//
//            let location = gestureRecognizer.location(in: pdfView)
//            if let page = pdfView.page(for: location,
//                                       nearest: true) {
//                currentTextAnnotation = page.annotation(at: location)
//
//                print("ks: \(page.bounds(for: .mediaBox))")
//
//                if currentTextAnnotation != nil {
//                    // FIXME: - to method
//                    pdfView.removeGestureRecognizer(drawingGestureRecognizer)
//                    pdfView.addGestureRecognizer(panGestureRecognizer)
//                    pdfView.addGestureRecognizer(pinchGestureRecognizer)
//                }
//            }
//
//
//            return false
//        }
        return false
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

    private func createDrawAnnotation(page: PDFPage,
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

    private func createTextAnnotation(page: PDFPage,
                                      bounds: CGRect,
                                      color: UIColor,
                                      width: CGFloat,
                                      alpha: CGFloat) -> PDFAnnotation {

        let annotation = PDFEditAnnotation(bounds: bounds,
                                       forType: .widget,
                                       withProperties: nil)
        annotation.fieldName = UUID().uuidString
        annotation.widgetFieldType = .text
        annotation.fontColor = color.withAlphaComponent(alpha)
        annotation.font = UIFont.systemFont(ofSize: width)
        annotation.isMultiline = true

        let border = PDFBorder()
        border.lineWidth = 1.0
        annotation.border = border

        annotation.widgetStringValue = "Text here..."

        let appearance = PDFAppearanceCharacteristics()
        appearance.borderColor = color
        appearance.backgroundColor = color.withAlphaComponent(0.1)

        annotation.setValue(appearance, forAnnotationKey: .widgetAppearanceDictionary)

//        appearance.rotation = 90
//        if let value = annotation.value(forAnnotationKey: .widgetAppearanceDictionary) as? PDFAppearanceCharacteristics {
//            print("ksTag annotationKeyValues: \(annotation.annotationKeyValues)")
//            print("ksTag appearanceCharacteristicsKeyValues: \(value.appearanceCharacteristicsKeyValues)")
//        }

        return annotation
    }

    private func eraseAnnotationAtPoint(point: CGPoint,
                                        page: PDFPage) {
        for annotation in page.annotations {
            if currentTextAnnotation === annotation.removePath(at: point) {
                currentTextAnnotation = nil
            }
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

    private func findTextView(in searchView: UIView) -> UITextView? {
        for view in searchView.subviews {
            if view.isKind(of: UITextView.self) {
                return view as? UITextView
            } else {
                return findTextView(in: view)
            }
        }
        return nil
    }

}
