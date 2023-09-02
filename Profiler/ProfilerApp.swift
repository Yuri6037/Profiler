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

import SwiftUI

class AppGlobals: ObservableObject {
    @Published var progress: Progress? = nil;
    @Published var projectSelection: Project?;
    @Published var errorHandler: ErrorHandler = ErrorHandler();
    @Published var progressList: ProgressList = ProgressList();
    lazy var store: Store = {
#if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Store.preview
        }
#endif
        return Store(errorHandler: { error in
            self.errorHandler.pushError(AppError(fromNSError: error));
        })
    }()
    lazy var adaptor: NetworkAdaptor = {
        NetworkAdaptor(
            errorHandler: errorHandler,
            container: store.container,
            progressList: progressList
        )
    }()
}

//TODO: Implement export and sync tool
//TODO: Fix tables under compact size class

@main
struct ProfilerApp: App {
    @StateObject var globals = AppGlobals();

    var body: some Scene {
        WindowGroup {
            ContentView(projectSelection: $globals.projectSelection)
                .environmentObject(globals.adaptor)
                .environmentObject(globals.errorHandler)
                .environmentObject(globals.progressList)
                .environment(\.persistentContainer, globals.store.container)
                .environment(\.managedObjectContext, globals.store.container.viewContext)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .onOpenURL { url in
                    globals.adaptor.connect(url: url);
                }
        }
        .commands {
            CommandGroup(replacing: .importExport) {
                Divider()
                Button("Share") { }
                Button("Export to Json...") {
                    if let proj = globals.projectSelection {
                        globals.store.utils.generateJson(proj);
                    } else {
                        globals.errorHandler.pushError(AppError(description: "Please select a project to export"));
                    }
                }
                Button("Export to CSV...") {}
                Button("Import from Json...") {}
                Button("Import from CSV...") {}
            }
        }
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
