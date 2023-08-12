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

//Swift is so much of a peace of shit that it just has banned the possibility
//of writing a single App for both iOS and macOS: it refuses #if os(macOS)!
class AppDelegate: NSObject, NSApplicationDelegate
{
    let errorHandler: ErrorHandler = ErrorHandler();
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
}

@main
struct ProfilerApp: App {
    //When swift finally accepts #if os(macOS) on a class use it to enable the app under iOS
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate;

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.errorHandler)
                .environment(\.persistentContainer, appDelegate.store.container)
                .environment(\.managedObjectContext, appDelegate.store.container.viewContext)
        }
    }
}
