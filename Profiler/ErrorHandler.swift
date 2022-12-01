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

import Foundation

struct AppError {
    let description: String;
    let reason: String?;
    let suggestion: String?;
    let help: String?;

    init(description: String, reason: String? = nil, suggestion: String? = nil, help: String? = nil) {
        self.description = description
        self.reason = reason
        self.suggestion = suggestion
        self.help = help
    }

    init(fromNSError error: NSError) {
        self.description = error.localizedDescription;
        self.reason = error.localizedFailureReason;
        self.suggestion = error.localizedRecoverySuggestion;
        self.help = error.helpAnchor;
    }

    init(fromError error: Error) {
        self.description = error.localizedDescription;
        self.reason = nil;
        self.suggestion = nil;
        self.help = nil;
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? { description }
    var failureReason: String? { reason }
    var recoverySuggestion: String? { suggestion }
    var helpAnchor: String? { help }
}

class ErrorHandler: ObservableObject {
    @Published var showError: Bool = false;

    var currentError: AppError {
        topError ?? AppError(description: "")
    }

    private var topError: AppError?;
    private var errorStack: [AppError] = [];

    func popError() {
        topError = nil;
        showError = false;
        if let error = errorStack.popLast() {
            topError = error;
            showError = true;
        }
    }

    func pushError(_ error: AppError) {
        if topError == nil {
            topError = error;
            showError = true;
        } else {
            self.errorStack.append(error);
        }
    }
}
