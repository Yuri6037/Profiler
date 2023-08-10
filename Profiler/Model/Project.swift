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

extension Target {
    var wArch: String { self.arch! }
    var wFamily: String { self.family! }
    var wOs: String { self.os! }
}

extension Cpu {
    var wName: String { self.name! }
    var wCoreCount: Int32 { self.coreCount }
}

extension Project {
    var wAppName: String { self.appName! }
    var wName: String { self.name! }
    var wCommandLine: String? { self.commandLine }
    var wTimestamp: Date { self.timestamp! }
    var wNodes: [SpanNode] { (self.nodes?.array ?? []) as! [SpanNode] }
    var wVersion: String? { self.version }
    var wCpu: Cpu? { self.cpu }
    var wTarget: Target? { self.target }
}
