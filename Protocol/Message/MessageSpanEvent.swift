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

public struct MessageHeaderSpanEvent: MessageHeader {
    public let id: UInt32;
    public let timestamp: Int64;
    public let level: Level;
    public let message: Vchar;

    public var payloadSize: Int { Int(message.length) };

    public static var size: Int = UInt32.size + Int64.size + Level.size + Vchar.size;

    public static func read(buffer: inout ByteBuffer) -> MessageHeaderSpanEvent {
        return MessageHeaderSpanEvent(
            id: .read(buffer: &buffer),
            timestamp: .read(buffer: &buffer),
            level: .read(buffer: &buffer),
            message: .read(buffer: &buffer)
        );
    }

    public func decode(buffer: inout ByteBuffer) throws -> Message {
        return .spanEvent(MessageSpanEvent(
            id: id,
            timestamp: timestamp,
            level: level,
            message: try message.readPayload(buffer: &buffer)
        ));
    }
}

public struct MessageSpanEvent {
    public let id: UInt32;
    public let timestamp: Int64;
    public let level: Level;
    public let message: String;
}
