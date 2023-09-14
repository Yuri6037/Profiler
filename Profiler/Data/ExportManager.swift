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
            let name = proj.wName + "_" + proj.wTimestamp.toISO8601() + ".bp3dprof"
            dialogText = "Exporting project " + proj.wAppName + " - " + proj.wName + "..."
            isRunning = true;
            StoreUtils(container: container).exportJson(proj, progressList: progressList, onFinish: {
                self.handleOnFinish($0, error: $1) { data in
                    let path = try FileUtils.getDataDirectory().appendingPathComponent(name)
                    try data.write(to: path)
                    DispatchQueue.main.async {
                        self.showDocumentDialog(type: UTType("com.github.bp3d.profiler.project")!, export: path)
                    }
                }
            })
        } else {
            errorHandler.pushError(AppError(description: "Please select a project to export"))
        }
    }

    func importJson(url: URL? = nil) {
        if let url {
            dialogText = "Importing project..."
            isRunning = true;
            do {
                StoreUtils(container: container).importJson(try Data(contentsOf: url), progressList: progressList, onFinish: {
                    self.handleOnFinish($0, error: $1) { flag in
                        DispatchQueue.main.async {
                            self.url = nil;
                        }
                        if !flag {
                            DispatchQueue.main.async {
                                self.errorHandler.pushError(AppError(description: "The project already already exists!"))
                            }
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
