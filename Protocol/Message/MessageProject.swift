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

public struct MessageProject: Message {
    public let appName: Vchar;
    public let name: Vchar;
    public let version: Vchar;
    public let commandLine: Vchar;
    public let target: Target;
    public let cpu: Cpu?;

    public static var size: Int = Size(bytes: ComponentVchar.size * 4)
        .add(ComponentTarget.self).add(ComponentOption<ComponentCpu>.self).bytes

    public static func read(reader: inout Reader) -> MessageProject {
        let appName = reader.read(ComponentVchar.self);
        let name = reader.read(ComponentVchar.self);
        let version = reader.read(ComponentVchar.self);
        let commandLine = reader.read(ComponentVchar.self);
        let target = reader.read(ComponentTarget.self);
        let cpu = reader.read(ComponentOption<ComponentCpu>.self);
        return MessageProject(appName: appName, name: name, version: version, commandLine: commandLine, target: target, cpu: cpu);
    }

    public var payloadSize: Int {
        Int(appName.length + name.length + version.length + commandLine.length)
        + target.payloadSize + (cpu?.payloadSize ?? 0)
    };
}
