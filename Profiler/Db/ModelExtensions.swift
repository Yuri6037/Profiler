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
import CoreData

enum Level {
    case trace;
    case debug;
    case info;
    case warning;
    case error;
    
    init(code: Int16) {
        switch code {
        case 0:
            self = .trace;
            break;
        case 1:
            self = .debug;
            break;
        case 3:
            self = .warning;
            break;
        case 4:
            self = .error;
            break;
        default:
            self = .info;
            break;
        }
    }

    var code: Int16 {
        switch self {
        case .trace:
            return 0;
        case .debug:
            return 1;
        case .info:
            return 2;
        case .warning:
            return 3;
        case .error:
            return 4;
        }
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

extension Project {
    var wId: UUID { self.id! }
    var wAppName: String { self.appName! }
    var wName: String { self.name! }
    var wCommandLine: String? { self.commandLine }
    var wTimestamp: Date { self.timestamp! }
    var wNodes: [SpanNode] { (self.nodes?.array ?? []) as! [SpanNode] }
    var wVersion: String? { self.version }
    var wCpu: Cpu? { self.cpu }
    var wTarget: Target? { self.target }

    static func new(context: NSManagedObjectContext) -> Project {
        let obj = Project(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension Project: Identifiable {}

extension Target {
    var wId: UUID { self.id! }
    var wArch: String { self.arch! }
    var wFamily: String { self.family! }
    var wOs: String { self.os! }

    static func new(context: NSManagedObjectContext) -> Target {
        let obj = Target(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension Target: Identifiable {}

extension Cpu {
    var wId: UUID { self.id! }
    var wName: String { self.name! }
    var wCoreCount: Int32 { self.coreCount }

    static func new(context: NSManagedObjectContext) -> Cpu {
        let obj = Cpu(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension Cpu: Identifiable {}

extension SpanMetadata {
    var wId: UUID { self.id! }
    var wLine: Int32? { self.line < 0 ? nil : self.line }
    var wName: String { self.name! }
    var wTarget: String { self.target! }
    var wFile: String? { self.file }
    var wLevel: Int16 { self.level }
    var wModulePath: String? { self.modulePath }

    static func new(context: NSManagedObjectContext) -> SpanMetadata {
        let obj = SpanMetadata(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension SpanMetadata: Identifiable {}

extension SpanNode {
    var wId: Int32 { self.id }
    var wPath: String { self.path! }
    var wEvents: [SpanEvent] { Array(self.events ?? []) }
    var wRuns: [SpanRun] { Array(self.runs ?? []) }
    var wMetadata: SpanMetadata? { self.metadata }
    
    var wAverageSeconds: UInt64 { UInt64(self.averageSeconds) }
    var wAverageMilliSeconds: UInt32 { UInt32(self.averageMilliSeconds) }
    var wAverageMicroSeconds: UInt32 { UInt32(self.averageMicroSeconds) }
    var wMinSeconds: UInt64 { UInt64(self.minSeconds) }
    var wMinMilliSeconds: UInt32 { UInt32(self.minMilliSeconds) }
    var wMinMicroSeconds: UInt32 { UInt32(self.minMicroSeconds) }
    var wMaxSeconds: UInt64 { UInt64(self.maxSeconds) }
    var wMaxMilliSeconds: UInt32 { UInt32(self.maxMilliSeconds) }
    var wMaxMicroSeconds: UInt32 { UInt32(self.maxMicroSeconds) }

    var wAverageSecs: Float64 {
        Float64(self.wAverageSeconds) + Float64(self.wAverageMilliSeconds) / Float64(1_000) + Float64(self.wAverageMicroSeconds) / Float64(1_000_000)
    }
    var wAverageMillis: Float64 {
        Float64(self.wAverageMilliSeconds) + Float64(self.wAverageMicroSeconds) / Float64(1_000)
    }
    var wAverageMicros: Float64 {
        Float64(self.wAverageMicroSeconds)
    }

    var wMinSecs: Float64 {
        Float64(self.wMinSeconds) + Float64(self.wMinMilliSeconds) / Float64(1_000) + Float64(self.wMinMicroSeconds) / Float64(1_000_000)
    }
    var wMinMillis: Float64 {
        Float64(self.wMinMilliSeconds) + Float64(self.wMinMicroSeconds) / Float64(1_000)
    }
    var wMinMicros: Float64 {
        Float64(self.wMinMicroSeconds)
    }

    var wMaxSecs: Float64 {
        Float64(self.wMaxSeconds) + Float64(self.wMaxMilliSeconds) / Float64(1_000) + Float64(self.wMaxMicroSeconds) / Float64(1_000_000)
    }
    var wMaxMillis: Float64 {
        Float64(self.wMaxMilliSeconds) + Float64(self.wMaxMicroSeconds) / Float64(1_000)
    }
    var wMaxMicros: Float64 {
        Float64(self.wMaxMicroSeconds)
    }
}

extension SpanNode: Identifiable {}

extension SpanRun {
    var wId: UUID { self.id! }
    var wVariables: [SpanVariable] { Array(self.variables ?? []) }
    var wMessage: String? { self.message }
    var wSeconds: UInt64 { UInt64(self.seconds) }
    var wMilliSeconds: UInt32 { UInt32(self.milliSeconds) }
    var wMicroSeconds: UInt32 { UInt32(self.microSeconds) }

    var wTimeSecs: Float64 {
        Float64(self.wSeconds) + Float64(self.wMilliSeconds) / Float64(1_000) + Float64(self.wMicroSeconds) / Float64(1_000_000)
    }
    var wTimeMillis: Float64 {
        Float64(self.wMilliSeconds) + Float64(self.wMicroSeconds) / Float64(1_000)
    }
    var wTimeMicros: Float64 {
        Float64(self.wMicroSeconds)
    }

    static func new(context: NSManagedObjectContext) -> SpanRun {
        let obj = SpanRun(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension SpanRun: Identifiable {}

extension SpanEvent {
    var wId: UUID { self.id! }
    var wVariables: [SpanVariable] { Array(self.variables ?? []) }
    var wMessage: String { self.message! }

    static func new(context: NSManagedObjectContext) -> SpanEvent {
        let obj = SpanEvent(context: context);
        obj.id = UUID();
        return obj;
    }
}

extension SpanEvent: Identifiable {}
