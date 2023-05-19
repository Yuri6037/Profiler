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

public enum Level {
    case trace;
    case debug;
    case info;
    case warning;
    case error;
    init(fromRaw: UInt8) {
        switch (fromRaw) {
        case 0:
            self = .trace;
            break;
        case 1:
            self = .debug;
            break;
        case 2:
            self = .info;
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
}

public struct ComponentLevel: Component {
    public typealias Out = Level;

    public static var size: Int = 1;

    public static func read(buffer: inout ByteBuffer) -> Level {
        let val = buffer.readInteger(endianness: .little, as: UInt8.self);
        return .init(fromRaw: val!);
    }
}