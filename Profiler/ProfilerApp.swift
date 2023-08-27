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
    @Published var errorHandler: ErrorHandler = ErrorHandler();
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
    lazy var adaptor: NetworkAdaptor = { NetworkAdaptor(errorHandler: errorHandler, container: store.container) }();
}

//TODO: Implement start/stop of recording
//TODO: Implement span parent/follows
//TODO: Implement export and sync tool

@main
struct ProfilerApp: App {
    @StateObject var globals = AppGlobals();

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globals.adaptor)
                .environmentObject(globals.errorHandler)
                .environment(\.persistentContainer, globals.store.container)
                .environment(\.managedObjectContext, globals.store.container.viewContext)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
                .onOpenURL { url in
                    globals.adaptor.connect(url: url);
                }
        }
#if os(macOS)
        Settings {
            SettingsView()
        }
#endif
    }
}
