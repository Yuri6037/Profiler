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

// TODO: Implement export and sync tool
// TODO: Fix tables under compact size class

@main
struct ProfilerApp: App {
    @StateObject var globals = AppGlobals()

    var body: some Scene {
        WindowGroup {
            ContentView(projectSelection: $globals.exportManager.projectSelection)
                .environmentObject(globals.adaptor)
                .environmentObject(globals.errorHandler)
                .environmentObject(globals.progressList)
                .environmentObject(globals.exportManager)
                .environment(\.persistentContainer, globals.store.container)
                .environment(\.managedObjectContext, globals.store.container.viewContext)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .onOpenURL { url in
                    globals.handleUrl(url)
                }
                .sheet(isPresented: $globals.exportManager.isRunning) {
                    VStack {
                        Text(globals.exportManager.dialogText)
                        ProgressView()
                        Divider()
                        ForEach(globals.progressList.array) { item in
                            SingleProgressView(progress: item)
                        }
                    }.padding()
                        .frame(minWidth: 256, minHeight: 150)
                        .presentationDetents([.fraction(0.5)])
                        .interactiveDismissDisabled()
                }
                .document(isPresented: $globals.exportManager.showExportDialog, type: globals.exportManager.fileType, export: globals.exportManager.url) { url in
                    // Run export system
                    globals.exportManager.saveExport(to: url)
                }
                .document(isPresented: $globals.exportManager.showImportDialog, type: globals.exportManager.fileType) { url in
                    // Run import system
                    globals.exportManager.importJson(url: url);
                }
        }
        .commands {
            CommandGroup(replacing: .importExport) {
                Divider()
                Button("Export...") {
                    globals.exportManager.exportJson();
                }
                Button("Export to CSV...") {}
                Divider()
                Button("Import...") {
                    globals.exportManager.importJson();
                }
                Button("Connect to server") {
                    
                }
            }
        }
        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}
