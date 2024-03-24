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

public struct MessageSpanEvent: Message {
    public let id: UInt32
    public let timestamp: Int64
    public let level: Level
    public let target: String
    public let module: String
    public let variables: [Field]

    public static func read(buffer: inout ByteBuffer) throws -> MessageSpanEvent {
        let id = UInt32.read(buffer: &buffer)
        let timestamp = Int64.read(buffer: &buffer)
        let level = Level.read(buffer: &buffer)
        let varCount = UInt8.read(buffer: &buffer)
        let target = try String.read(buffer: &buffer)
        let module = try String.read(buffer: &buffer)
        return MessageSpanEvent(
            id: id,
            timestamp: timestamp,
            level: level,
            target: target,
            module: module,
            variables: try List(count: Int(varCount)).read(buffer: &buffer)
        )
    }
}
