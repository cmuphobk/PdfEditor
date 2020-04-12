//
//  PDFEditAnnotation.swift
//  PDFEditor
//
//  Created by Кирилл on 18/09/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import Foundation
import PDFKit

class PDFEditAnnotation: PDFAnnotation {

    override var hasAppearanceStream: Bool {
        return true
    }

}
