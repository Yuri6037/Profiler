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

import CoreData
import Foundation
import Protocol

extension Level {
    init(code: Int16) {
        self.init(fromRaw: UInt8(code))
    }

    var name: String {
        switch self {
        case .trace:
            return "Trace"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }
}

extension SpanMetadata {
    var wLine: Int32? { line < 0 ? nil : line }
    var wName: String { name! }
    var wTarget: String { target! }
    var wFile: String? { file }
    var wLevel: Level { Level(code: level) }
    var wModulePath: String? { modulePath }
}

extension SpanRun {
    var wOrder: UInt { UInt(order) }
    var wVariables: [SpanVariable] { (variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String? { message }
    var wTime: Duration { Duration(nanoseconds: UInt64(time)) }
}

extension SpanEvent {
    var wOrder: UInt { UInt(order) }
    var wVariables: [SpanVariable] { (variables?.allObjects ?? []) as! [SpanVariable] }
    var wMessage: String { message! }
    var wTimestamp: Date { timestamp! }
    var wLevel: Level { Level(code: level) }
    var wTarget: String { target! }
    var wModule: String { module! }
}

extension SpanNode {
    var wOrder: UInt32 { UInt32(order) }
    var wPath: String { path! }
    var wMetadata: SpanMetadata? { metadata }
    var wDatasets: [Dataset] { (datasets?.allObjects ?? []) as! [Dataset] }

    var wAverageTime: Duration { Duration(nanoseconds: UInt64(bitPattern: averageTime)) }
    var wMinTime: Duration { Duration(nanoseconds: UInt64(bitPattern: minTime)) }
    var wMaxTime: Duration { Duration(nanoseconds: UInt64(bitPattern: maxTime)) }
}

extension SpanEvent: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let event = SpanEvent(context: context)
        event.module = "test"
        event.target = "test target"
        event.level = Int16(Level.warning.raw)
        event.timestamp = Date()
        event.message = "this is a test log message"
        return event as! Self
    }
}

extension SpanMetadata: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let metadata = SpanMetadata(context: context)
        metadata.name = "test"
        metadata.target = "test target"
        metadata.level = 0
        return metadata as! Self
    }
}

extension SpanNode: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let node = SpanNode(context: context)
        node.project = Project.newSample(context: context)
        node.path = "root"
        node.metadata = SpanMetadata.newSample(context: context)
        return node as! Self
    }
}
