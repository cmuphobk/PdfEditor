//
//  ViewController.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit
import PDFKit

class ViewController: UIViewController {

    lazy var pdfEditView: PDFEditView = {
        let pdfEditView = PDFEditView()
        return pdfEditView
    }()

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        pdfEditView.frame = view.bounds
        if !pdfEditView.isDescendant(of: view) {
            view.addSubview(pdfEditView)
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPDF()
    }


    private func fetchPDF() {
        guard let url = URL(string: "https://www.tutorialspoint.com/swift/swift_tutorial.pdf") else { return }
        let urlSession = URLSession(configuration: .default,
                                    delegate: self,
                                    delegateQueue: nil)

        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
}

extension ViewController:  URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        print("downloadLocation:", location)

        let pdfDocument = PDFDocument(url: location)

        DispatchQueue.main.async { [weak self] in
            self?.pdfEditView.document = pdfDocument
        }

    }
}

