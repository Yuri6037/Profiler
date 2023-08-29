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
import Foundation
import Protocol

struct DisplaySpanRun: Identifiable {
    let id: UUID;
    let time: String;
    let message: String;
    let variables: String;

    init(fromModel model: SpanRun) {
        self.time = model.wTime.formatted()
        self.message = model.wMessage ?? "No message specified";
        self.variables = model.wVariables.map { item in item.data ?? "" }.joined(separator: ", ");
        self.id = UUID();
    }
}

struct DisplaySpanEvent: Identifiable {
    let id: UUID;
    let variables: String;
    let message: String;
    let level: String;
    let timestamp: String;
    let target: String;
    let module: String;

    init(fromModel model: SpanEvent) {
        self.timestamp = model.wTimestamp.formatted()
        self.variables = model.wVariables.map { item in item.data ?? "" }.joined(separator: ", ")
        self.message = model.wMessage;
        self.level = model.wLevel.name;
        self.id = UUID();
        self.target = model.wTarget;
        self.module = model.wModule;
    }
}

struct DisplayDataset: Identifiable {
    let id: UUID;
    let path: String;
    let timestamp: String;
    let average: String;
    let median: String;
    let min: String;
    let max: String;

    init(fromModel model: Dataset) {
        self.id = UUID()
        self.timestamp = model.wTimestamp.formatted();
        self.average = model.wAverageTime.formatted();
        self.median = model.wMedianTime.formatted();
        self.min = model.wMinTime.formatted();
        self.max = model.wMaxTime.formatted();
        self.path = model.wNode.wPath;
    }
}

extension Level {
    var color: Color {
        switch self {
        case .trace:
            return .cyan;
        case .debug:
            return .accentColor;
        case .info:
            return .green;
        case .warning:
            return .yellow;
        case .error:
            return .red;
        }
    }
}

extension Duration {
    func formatted() -> String {
        if Int(seconds) > 0 {
            return seconds.formatted() + "s";
        } else if Int(milliseconds) > 0 {
            return milliseconds.formatted() + "ms";
        } else if Int(microseconds) > 0 {
            return microseconds.formatted() + "µs";
        } else {
            return nanoseconds.formatted() + "ns";
        }
    }
}
