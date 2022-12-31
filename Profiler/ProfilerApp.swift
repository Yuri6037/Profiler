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
import ErrorHandler

#if os(macOS)
import ProfilerServiceView
#endif

//TODO: support responding to url types
//TODO: Support import progress

@main
struct ProfilerApp: App {
    @StateObject var errorHandler: ErrorHandler = ErrorHandler();
    @State var database: Database;
    @State var importManager: ImporterManager;

    init() {
        _database = .init(initialValue: Database());
        _importManager = .init(initialValue: ImporterManager(container: _database.wrappedValue.container));
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, database.container.viewContext)
                .environment(\.database, database)
                .environment(\.importerManager, importManager)
                .environmentObject(errorHandler)
                .onAppear {
                    importManager.setErrorBlock { error in
                        errorHandler.pushError(AppError(fromNSError: error as NSError));
                    }
                    importManager.start();
                    if let error = database.lastError {
                        errorHandler.pushError(AppError(fromNSError: error));
                    }
                    database.errorEvent = { error in
                        errorHandler.pushError(AppError(fromNSError: error));
                    }
                }
        }
#if os(macOS)
        .commands {
            CommandGroup(replacing: .importExport) {
                Button("Import") {
                    openFileDialog(onPick: { url in
                        self.importProject(dir: url.path);
                    })
                }
                Button("Open data path") {
                    NSWorkspace.shared.open(Database.url)
                }
            }
        }
#endif // Garbagely broken stupid Swift language has broken preprocessor directives
        // not even able to handle a single #if block unlike C, C++ or Objective-C!!
#if os(macOS)
        WindowGroup {
            ProfilerServiceView.ContentView()
        }
        .handlesExternalEvents(matching: ["*"])
#endif
    }

    func importProject(dir: String) {
        importManager.importDirectory(dir, deleteAfterImport: false);
    }
}
