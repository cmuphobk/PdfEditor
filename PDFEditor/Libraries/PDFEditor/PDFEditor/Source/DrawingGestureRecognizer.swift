//
//  PDFEditView.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//


import UIKit

protocol DrawingGestureRecognizerDelegate: class {
    func drawingBegan(_ location: CGPoint)
    func drawingMoved(_ location: CGPoint)
    func drawingEnded(_ location: CGPoint)
}

class DrawingGestureRecognizer: UIGestureRecognizer {

    // MARK: - Stored

    weak var drawingDelegate: DrawingGestureRecognizerDelegate?

    // MARK: - Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if
            let numberOfTouches = event?.allTouches?.count,
            numberOfTouches == 1,
            let touch = touches.first
        {
            state = .began
            let location = touch.location(in: view)
            drawingDelegate?.drawingBegan(location)
        } else {
            state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .changed
        guard let location = touches.first?.location(in: view) else { return }
        drawingDelegate?.drawingMoved(location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: view) else {
            state = .ended
            return
        }
        drawingDelegate?.drawingEnded(location)
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let _ = touches.first?.location(in: view) else {
            state = .ended
            return
        }
        state = .failed
    }
}
