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

public struct Duration {
    public let nanoseconds: UInt64;
    public var microseconds: Float64 { Float64(nanoseconds) / 1000.0 }
    public var seconds: Float64 { Float64(microseconds) / 1000000000.0 }
    public var milliseconds: Float64 { Float64(microseconds) / 1000000.0 }

    public init(nanoseconds: UInt64) {
        self.nanoseconds = nanoseconds;
    }

    public init(seconds: UInt32, milliseconds: UInt32, microseconds: UInt32) {
        self.nanoseconds = UInt64(seconds * 1000000000) + UInt64(milliseconds * 1000000) + UInt64(microseconds * 1000);
    }

    public init(seconds: UInt32, nanoseconds: UInt32) {
        self.nanoseconds = UInt64(seconds * 1000000000) + UInt64(nanoseconds);
    }
}

extension Duration: Component {
    public static var size: Int = UInt32.size * 2;

    public static func read(buffer: inout ByteBuffer) -> Duration {
        let seconds = UInt32.read(buffer: &buffer);
        let nanos = UInt32.read(buffer: &buffer);
        return Duration(seconds: seconds, nanoseconds: nanos);
    }
}
