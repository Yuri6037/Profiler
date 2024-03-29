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

struct DisplaySpanRun: Identifiable {
    var id: UUID;
    var time: String;
    var message: String;
    var variables: String;

    init(fromModel model: SpanRun) {
        if model.wSeconds > 0 {
            self.time = model.wTimeSecs.formatted() + "s";
        } else if model.wMilliSeconds > 0 {
            self.time = model.wTimeMillis.formatted() + "ms";
        } else {
            self.time = model.wTimeMicros.formatted() + "µs";
        }
        self.message = model.wMessage ?? "No message specified";
        self.variables = model.wVariables.map { item in item.data ?? "" }.joined(separator: ", ");
        self.id = UUID();
    }
}

struct DisplaySpanEvent: Identifiable {
    var id: UUID;
    var variables: String;
    var message: String;

    init(fromModel model: SpanEvent) {
        self.variables = model.wVariables.map { item in item.data ?? "" }.joined(separator: ", ")
        self.message = model.wMessage;
        self.id = UUID();
    }
}
