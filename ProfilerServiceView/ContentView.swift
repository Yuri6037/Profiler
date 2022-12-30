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

class CloseConfirmDelegate: NSObject, ObservableObject, NSWindowDelegate {
    @Published var showCloseDialog = false;
    var closeRequested = false;
    private var _window: NSWindow?;

    func close() {
        _window?.delegate = nil;
        _window?.close();
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        _window = sender;
        closeRequested = true;
        showCloseDialog = true;
        return false;
    }
}

public struct ContentView: View {
    @StateObject var delegate: CloseConfirmDelegate = CloseConfirmDelegate();
    @State var subscribtion: ProfilerSubscribtion?;
    @StateObject private var errorHandler: ErrorHandler = ErrorHandler();

    public init() {} //Thanks garbagely broken Swift language unable to see that the struct is public and not internal!!

    public var body: some View {
        VStack {
            if let subscribtion = subscribtion {
                ProfilerView(subscribtion: subscribtion).environmentObject(errorHandler)
            }
        }
        .background(WindowReader { window in
            window?.delegate = delegate;
        })
        .alert("Closing...", isPresented: $delegate.showCloseDialog, actions: {
            Button("Import") {
                
            }.keyboardShortcut(.defaultAction)
            Button("Delete", role: .destructive) {
                do {
                    try subscribtion?.delete();
                    delegate.close();
                } catch {
                    errorHandler.pushError(AppError(fromError: error));
                }
            }
        }, message: {
            Text("What would you like to do with this dataset?")
        })
        .alert(isPresented: $errorHandler.showError, error: errorHandler.currentError) {
            Button("OK") {
                errorHandler.popError()
                if delegate.closeRequested {
                    delegate.close();
                }
            }
        }
        .onOpenURL { url in
            print(url)
            do {
                try ProfilerServiceManager.getInstance().connect(address: url.host!, callback: { subscribtion = $0 });
            } catch {
                errorHandler.pushError(AppError(fromError: error));
            }
        }
        .onAppear {
            ProfilerServiceManager.getInstance().bindErrorHandler(errorHandler);
        }
        .onDisappear {
            ProfilerServiceManager.getInstance().unbindErrorHandler(errorHandler);
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
