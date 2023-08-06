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

public struct MessageHeaderProject: MessageHeader {
    public let appName: Vchar;
    public let name: Vchar;
    public let version: Vchar;
    public let commandLine: Vchar;
    public let target: TargetHeader;
    public let cpu: CpuHeader?;

    public static var size: Int = Size(bytes: Vchar.size * 4).add(TargetHeader.self).add(Option<CpuHeader>.self).bytes

    public static func read(reader: inout Reader) -> MessageHeaderProject {
        let appName = reader.read(Vchar.self);
        let name = reader.read(Vchar.self);
        let version = reader.read(Vchar.self);
        let commandLine = reader.read(Vchar.self);
        let target = reader.read(TargetHeader.self);
        let cpu = reader.read(Option<CpuHeader>.self);
        return MessageHeaderProject(appName: appName, name: name, version: version, commandLine: commandLine, target: target, cpu: cpu);
    }

    public var payloadSize: Int {
        Int(appName.length + name.length + version.length + commandLine.length)
        + target.payloadSize + (cpu?.payloadSize ?? 0)
    };

    public func decode(reader: inout Reader) throws -> Message {
        return .project(MessageProject(
            appName: try reader.read(appName),
            name: try reader.read(name),
            version: try reader.read(version),
            commandLine: try reader.read(commandLine),
            target: try reader.read(target),
            cpu: try reader.read(cpu)
        ));
    }
}

public struct MessageProject {
    public let appName: String;
    public let name: String;
    public let version: String;
    public let commandLine: String;
    public let target: Target;
    public let cpu: Cpu?;
}
