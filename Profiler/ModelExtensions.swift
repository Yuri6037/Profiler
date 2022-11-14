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

extension Project {
    var wId: UUID { self.id! }
    var wName: String { self.name! }
    var wTimestamp: Date { self.timestamp! }
    var wNodes: [SpanNode] { (self.nodes?.array ?? []) as! [SpanNode] }
    var wVersion: String? { self.version }
    var wSystem: System? { self.system }
}

extension SpanMetadata {
    var wId: UUID { self.id! }
    var wLine: Int32? { self.line < 0 ? nil : self.line }
    var wName: String { self.name! }
    var wTarget: String { self.target! }
    var wFile: String? { self.file }
    var wLevel: Int16 { self.level }
    var wModulePath: String? { self.modulePath }
}

extension SpanNode {
    var wId: Int32 { self.id }
    var wPath: String { self.path! }
    var wEvents: [SpanEvent] { (self.events?.allObjects ?? []) as! [SpanEvent] }
    var wRuns: [SpanRun] { (self.runs?.allObjects ?? []) as! [SpanRun] }
}

extension SpanRun {
    var wId: UUID { self.id! }
    var wVariables: [SpanVariable] { (self.variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String? { self.message }
    var wTime: Float64 { self.time }
}

extension SpanEvent {
    var wId: UUID { self.id! }
    var wVariables: [SpanVariable] { (self.variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String { self.message! }
}
