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
import NIO

public struct Size {
    public let bytes: Int;

    init(bytes: Int = 0) {
        self.bytes = bytes;
    }

    public func add<T: Component>(_ c: T.Type) -> Size {
        return Size(bytes: self.bytes + c.size);
    }
}

public struct Reader {
    var buffer: ByteBuffer;

    public mutating func read<T: Component>(_ c: T.Type) -> T {
        return c.read(buffer: &buffer);
    }

    public mutating func read<T: PayloadComponent>(_ c: T) throws -> T.PayloadOut {
        return try c.readPayload(buffer: &buffer);
    }

    public mutating func read<T: PayloadComponent>(_ c: T?) throws -> T.PayloadOut? {
        if let c = c {
            return try c.readPayload(buffer: &buffer);
        } else {
            return nil;
        }
    }
}

public protocol MessageHeader {
    static var size: Int { get };
    static func read(reader: inout Reader) -> Self;
    var payloadSize: Int { get };

    func decode(reader: inout Reader) throws -> Message;
}

public protocol Writable {
    func write(buffer: inout ByteBuffer);
}

public enum Message {
    case serverConfig(MessageServerConfig);
    case project(MessageProject);
}
