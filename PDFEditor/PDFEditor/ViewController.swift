//
//  ViewController.swift
//  PDFEditor
//
//  Created by Кирилл on 28/08/2019.
//  Copyright © 2019 Кирилл. All rights reserved.
//

import UIKit
import PDFEditor

// FIXME: - incapsulate in PDFEditor
import PDFKit

final class ViewController: UIViewController {

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

        // FIXME: - Download PDF
        fetchPDF()

        // FIXME: - Save PDF without data getting
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 60.0) { [weak self] in
            guard let pdfData = self?.pdfEditView.document.dataRepresentation() else { return }

            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                    .userDomainMask,
                                                                    true)[0]

            let url = URL(fileURLWithPath: "\(documentsPath)/file.pdf")
            try? pdfData.write(to: url)
        }
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

        // FIXME: - initialize pdfEditView with url
        let pdfDocument = PDFDocument(url: location)

        DispatchQueue.main.async { [weak self] in
            self?.pdfEditView.document = pdfDocument
        }

    }
}

