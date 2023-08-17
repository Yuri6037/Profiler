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
import CoreData
import Protocol

extension Level {
    init(code: Int16) {
        self.init(fromRaw: UInt8(code));
    }

    var name: String {
        switch self {
        case .trace:
            return "Trace";
        case .debug:
            return "Debug";
        case .info:
            return "Info";
        case .warning:
            return "Warning";
        case .error:
            return "Error";
        }
    }
}

extension SpanMetadata {
    var wLine: Int32? { self.line < 0 ? nil : self.line }
    var wName: String { self.name! }
    var wTarget: String { self.target! }
    var wFile: String? { self.file }
    var wLevel: Level { Level(code: self.level) }
    var wModulePath: String? { self.modulePath }
}

extension SpanRun {
    var wOrder: UInt { UInt(self.order) }
    var wVariables: [SpanVariable] { (self.variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String? { self.message }
    var wTime: Duration { Duration(nanoseconds: UInt64(self.time)) }
}

extension SpanEvent {
    var wOrder: UInt { UInt(self.order) }
    var wVariables: [SpanVariable] { (self.variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String { self.message! }
    var wTimestamp: Date { self.timestamp! }
    var wLevel: Level { Level(code: self.level) }
    var wTarget: String { self.target! }
    var wModule: String { self.module! }
}

extension SpanNode {
    var wOrder: UInt32 { UInt32(self.order) }
    var wPath: String { self.path! }
    var wMetadata: SpanMetadata? { self.metadata }

    var wAverageTime: Duration { Duration(nanoseconds: UInt64(bitPattern: self.averageTime)) }
    var wMinTime: Duration { Duration(nanoseconds: UInt64(bitPattern: self.minTime)) }
    var wMaxTime: Duration { Duration(nanoseconds: UInt64(bitPattern: self.maxTime)) }
}

extension SpanMetadata: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let metadata = SpanMetadata(context: context);
        metadata.name = "test";
        metadata.target = "test target";
        metadata.level = 0;
        return metadata as! Self;
    }
}

extension SpanNode: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let node = SpanNode(context: context);
        node.project = Project.newSample(context: context);
        node.path = "root";
        node.metadata = SpanMetadata.newSample(context: context);
        return node as! Self;
    }
}
