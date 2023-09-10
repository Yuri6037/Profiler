// Copyright 2023 Yuri6037
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy
// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
// THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS
// IN THE SOFTWARE.

import UniformTypeIdentifiers
import Foundation
import CoreData
import Combine

class ExportManager: ObservableObject {
    private let container: NSPersistentContainer;
    private let errorHandler: ErrorHandler;
    private let progressList: ProgressList;
    @Published var projectSelection: Project?
    @Published var isRunning = false;
    @Published var showExportDialog = false;
    @Published var showImportDialog = false;
    @Published var dialogText = "";
    @Published var url: URL? = nil;
    @Published var fileType: UTType = .json;

    init(container: NSPersistentContainer, errorHandler: ErrorHandler, progressList: ProgressList) {
        self.container = container;
        self.errorHandler = errorHandler;
        self.progressList = progressList;
    }

    private func showDocumentDialog(type: UTType, export: URL? = nil) {
        self.fileType = type;
        if export != nil {
            url = export;
            DispatchQueue.main.async {
                self.showExportDialog = true;
                self.showImportDialog = false;
            }
        } else {
            showImportDialog = true;
            showExportDialog = false;
        }
    }

    private func handleOnFinish<T>(_ data: T?, error: NSError?, callback: (T) throws -> Void) {
        DispatchQueue.main.async {
            self.isRunning = false;
        }
        if let data {
            do {
                try callback(data);
            } catch {
                DispatchQueue.main.async {
                    self.errorHandler.pushError(AppError(fromError: error))
                }
            }
        }
        if let error {
            DispatchQueue.main.async {
                self.errorHandler.pushError(AppError(fromNSError: error))
            }
        }
    }
    
    func saveExport(to: URL) {
#if os(macOS)
        if let url {
            do {
                try FileUtils.copy(from: url, to: to)
            } catch {
                errorHandler.pushError(AppError(fromError: error))
            }
        } else {
            errorHandler.pushError(AppError(description: "Cannot save NULL export"))
        }
#endif
    }

    func exportJson(_ project: Project? = nil) {
        if let proj = projectSelection ?? project {
            dialogText = "Exporting to JSON..."
            isRunning = true;
            StoreUtils(container: container).exportJson(proj, progressList: progressList, onFinish: {
                self.handleOnFinish($0, error: $1) { data in
                    let path = try FileUtils.getDataDirectory().appendingPathComponent("export.json")
                    try data.write(to: path)
                    DispatchQueue.main.async {
                        self.showDocumentDialog(type: .json, export: path)
                    }
                }
            })
        } else {
            errorHandler.pushError(AppError(description: "Please select a project to export"))
        }
    }

    func importJson(url: URL? = nil) {
        if let url {
            dialogText = "Importing from JSON..."
            isRunning = true;
            do {
                StoreUtils(container: container).importJson(try Data(contentsOf: url), progressList: progressList, onFinish: {
                    self.handleOnFinish((), error: $0) {
                        DispatchQueue.main.async {
                            self.url = nil;
                        }
                    }
                })
            } catch {
                errorHandler.pushError(AppError(fromError: error))
            }
        } else {
            showDocumentDialog(type: .json)
        }
    }
}

class AppGlobals: ObservableObject {
    @Published var progress: Progress? = nil
    @Published var errorHandler: ErrorHandler = .init()
    @Published var progressList: ProgressList = .init()
    
    lazy var store: Store = {
#if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Store.preview
        }
#endif
        return Store(errorHandler: { error in
            self.errorHandler.pushError(AppError(fromNSError: error))
        })
    }()
    
    lazy var adaptor: NetworkAdaptor = .init(
        errorHandler: errorHandler,
        container: store.container,
        progressList: progressList
    )
    
    lazy var exportManager: ExportManager = .init(container: store.container, errorHandler: errorHandler, progressList: progressList)

    var anyCancellable: AnyCancellable? = nil
    
    init() {
        anyCancellable = exportManager.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
}
