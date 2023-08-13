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

import Foundation

public struct AppError {
    public let description: String;
    public let reason: String?;
    public let suggestion: String?;
    public let help: String?;

    public init(description: String, reason: String? = nil, suggestion: String? = nil, help: String? = nil) {
        self.description = description
        self.reason = reason
        self.suggestion = suggestion
        self.help = help
    }

    public init(fromNSError error: NSError) {
        self.description = error.localizedDescription;
        self.reason = error.localizedFailureReason;
        self.suggestion = error.localizedRecoverySuggestion;
        self.help = error.helpAnchor;
    }

    public init(fromError error: Error) {
        self.description = error.localizedDescription;
        self.reason = nil;
        self.suggestion = nil;
        self.help = nil;
    }
}

extension AppError: LocalizedError {
    public var errorDescription: String? { description }
    public var failureReason: String? { reason }
    public var recoverySuggestion: String? { suggestion }
    public var helpAnchor: String? { help }
}

public class ErrorHandler: ObservableObject, Hashable, Equatable {
    @Published public var showError: Bool = false;

    public var currentError: AppError {
        topError ?? AppError(description: "")
    }

    private var topError: AppError?;
    private var errorStack: [AppError] = [];

    public init() {} //Thanks garbagely broken Swift language unable to see that the class is public and not internal!!

    public func popError() {
        topError = nil;
        showError = false;
        DispatchQueue.main.async {
            if let error = self.errorStack.popLast() {
                self.topError = error;
                self.showError = true;
            }
        }
    }

    public func pushError(_ error: AppError) {
        if topError == nil {
            topError = error;
            showError = true;
        } else {
            self.errorStack.append(error);
        }
    }

    public static func == (lhs: ErrorHandler, rhs: ErrorHandler) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs);
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
