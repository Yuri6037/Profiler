// Copyright 2022 Yuri6037
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

import SwiftUI

@main
struct ProfilerApp: App {
    @StateObject var errorHandler: ErrorHandler = ErrorHandler();
    @State var importTask: ProjectImporter?;

    init() {
        if let error = Database.shared.lastError { //This automatically loads the database
            errorHandler.pushError(AppError(fromNSError: error));
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, Database.shared.container.viewContext)
                .environmentObject(errorHandler)
                .onAppear {
                    if let error = Database.shared.lastError {
                        errorHandler.pushError(AppError(fromNSError: error));
                    }
                    Database.shared.errorEvent = { error in
                        errorHandler.pushError(AppError(fromNSError: error));
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .importExport) {
#if os(macOS)
                Button("Import") {
                    openFileDialog(onPick: { url in
                        self.importProject(dir: url.path);
                    })
                }
#endif
#if os(macOS)
                Button("Open data path") {
                    NSWorkspace.shared.open(Database.url)
                }
#endif
            }
        }
    }

    func importProject(dir: String) {
        if self.importTask != nil {
            errorHandler.pushError(AppError(description: "A project is already being imported, please wait..."));
            return;
        }
        self.importTask = ProjectImporter(directory: dir, container: Database.shared.container);
        do {
            try self.importTask?.loadProject();
            try self.importTask?.importTree();
        } catch {
            errorHandler.pushError(AppError(fromNSError: error as NSError));
        }
    }
}
